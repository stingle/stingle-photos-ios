//
//  STKeyChainService.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/19/21.
//

import KeychainSwift

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
