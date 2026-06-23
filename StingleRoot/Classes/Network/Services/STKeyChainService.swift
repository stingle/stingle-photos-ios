//
//  STKeyChainService.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/19/21.
//

import KeychainSwift
import LocalAuthentication
import Security

class STKeyChainService {

    private let keyChain = KeychainSwift()

    // `.accessibleAfterFirstUnlockThisDeviceOnly`: the item becomes readable after
    // the first device unlock following a reboot and STAYS readable while the
    // device later locks. KeychainSwift's default (`.accessibleWhenUnlocked`) is
    // unavailable whenever the device is locked, which made the biometric-unlock
    // read fail after a long background and silently fall back to the password
    // dialog. Not synced to other devices (ThisDeviceOnly) since it gates app unlock.
    private let access: KeychainSwiftAccessOptions = .accessibleAfterFirstUnlockThisDeviceOnly
    private let migratedFlagKey = "STKeyChainService.passwordKey.afterFirstUnlock.migrated"

    // Account name for the biometric-gated secret. Unlike `passwordKey` (which is only
    // accessibility-gated and therefore readable by anyone with filesystem/keychain access after the
    // first device unlock), this item carries a `.biometryCurrentSet` SecAccessControl, so the Secure
    // Enclave will only release it on a live Face ID / Touch ID match. The item is also invalidated
    // automatically if the enrolled biometric set changes.
    private let biometricKeyAccount = "PasswordKey.biometric"

    var passwordKey: String? {
        set {
            self.set(value: newValue, for: .passwordKey)
        } get {
            return self.value(for: .passwordKey)
        }
    }

    //MARK: - Public methods

    func deleteAll() {
        KeyChainKey.allCases.forEach { key in
            self.keyChain.delete(key.rawValue)
        }
        self.deleteBiometricSecret()
    }

    //MARK: - Biometric-gated secret (Secure Enclave)

    /// Stores `value` so it can only be read back after a successful biometric match. Returns false if
    /// the access control could not be created or the item could not be stored. Storing does NOT
    /// require a biometric prompt; only reading does.
    @discardableResult
    func setBiometricSecret(_ value: String?) -> Bool {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.biometricKeyAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard let value = value, let data = value.data(using: .utf8) else {
            return true
        }
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(nil,
                                                           kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                           .biometryCurrentSet,
                                                           &error) else {
            return false
        }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.biometricKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    /// Reads the biometric-gated secret. Passing an `LAContext` lets the caller control the prompt and
    /// allows a single biometric evaluation to authorize the read. Returns the decoded value (nil on
    /// failure) AND the raw `OSStatus` so the caller can distinguish an explicit user cancellation /
    /// auth failure (must NOT be silently recovered from) from an environment/availability failure.
    func biometricSecret(context: LAContext, reason: String) -> (value: String?, status: OSStatus) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.biometricKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        query[kSecUseOperationPrompt as String] = reason
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return (nil, status)
        }
        return (String(data: data, encoding: .utf8), status)
    }

    /// True if a biometric-gated secret exists, WITHOUT triggering a biometric prompt (UI skipped).
    /// Probing a `.biometryCurrentSet` item: requesting the data with the UI suppressed returns
    /// `errSecInteractionNotAllowed` when the item is present (it would need auth to actually return),
    /// which is the reliable "exists" signal.
    func hasBiometricSecret() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.biometricKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    @discardableResult
    func deleteBiometricSecret() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.biometricKeyAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    //MARK: - Private methods

    private func set(value: String?, for key: KeyChainKey) {
        guard let value = value else {
            self.keyChain.delete(key.rawValue)
            return
        }
        self.keyChain.set(value, forKey: key.rawValue, withAccess: self.access)
    }

    private func value(for key: KeyChainKey) -> String? {
        let result = self.keyChain.get(key.rawValue)
        if key == .passwordKey, let result = result {
            self.migrateAccessibilityIfNeeded(value: result)
        }
        return result
    }

    // One-time migration for installs that stored the key before this change (with
    // the old `.accessibleWhenUnlocked`). Re-store it with the new accessibility the
    // first time it is successfully read — the device is unlocked at that moment, so
    // the rewrite is safe. KeychainSwift.set deletes-then-adds atomically under a
    // lock, so this just rewrites the same value with the stronger access class.
    private func migrateAccessibilityIfNeeded(value: String) {
        guard !UserDefaults.standard.bool(forKey: self.migratedFlagKey) else {
            return
        }
        let success = self.keyChain.set(value, forKey: KeyChainKey.passwordKey.rawValue, withAccess: self.access)
        if success {
            UserDefaults.standard.set(true, forKey: self.migratedFlagKey)
        }
    }

}

private extension STKeyChainService {

    enum KeyChainKey: String, CaseIterable {
        case passwordKey = "PasswordKey"
    }

}
