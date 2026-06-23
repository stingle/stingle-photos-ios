//
//  STBiometricAuthenticationServices.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/20/21.
//

import LocalAuthentication
import Security

public class STBiometricAuthServices {

    private let keyChainService = STKeyChainService()
    private let userDefaultsKey = "biometricAuthDatakey"
    private let encryptedPasswordKey = "encryptedPasswordKey"

    public init() {}

    /// Secure-Enclave-gated keychain items (`.biometryCurrentSet`) are not reliably storable/readable
    /// on the Simulator (no real Secure Enclave), which would break the dev unlock loop. On the
    /// Simulator we fall back to the legacy mechanism (ungated secret + an LAContext check) — exactly
    /// the prior behavior — while real devices use the hardened, biometric-gated path. The Simulator
    /// is not a real attack surface, so this does not weaken the shipping product.
    private var useSecureEnclaveGate: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    //MARK: - Public methods

    public func removeBiometricAuth() {
        self.keyChainService.passwordKey = nil
        self.keyChainService.deleteBiometricSecret()
        self.encryptedPassword = nil
    }

    public func onBiometricAuth(password: String, _ success: ( () -> Void)? = nil, failure:  ((_ error: IError) -> Void)? = nil) {
        do {
            try self.setApp(password: password)
            success?()
        } catch {
            failure?(AuthError.error(error: error))
        }
    }

    public func unlockApp(_ success: @escaping (_ password: String) -> Void, failure:  @escaping (_ error: IError) -> Void) {
        self.checkBiometry({ [weak self] in
            self?.unlockAppWithCheckin(success, failure)
        }, failure)
    }

    public func unlockApp(password: String) throws {
        let key = try STApplication.shared.crypto.getPrivateKey(password: password)
        STKeyManagement.key = key
        // Self-heal: if biometric unlock is enabled but the stored credential is missing OR no longer
        // matches this password (e.g. iOS invalidated the gated item on biometric re-enrollment, or a
        // reinstall/logout cycle left UserDefaults and the keychain out of sync), re-arm it from this
        // just-verified password. This is what makes the one-time password login restore Face ID /
        // Touch ID for an existing user.
        if STAppSettings.current.security.authentication.unlock,
           !self.storedCredentialMatches(password: password) {
            try? self.setApp(password: password)
        }
    }

    //MARK: - Private methods

    private func setApp(password: String) throws {

        guard self.isValiedPassword(password: password) else {
            throw AuthError.passwordNotValied
        }
        let crypto = STApplication.shared.crypto
        guard let key = crypto.generateSecretKey(), let encrypted = crypto.encrypted(text: password, for: key) else {
            throw AuthError.unknown
        }
        self.encryptedPassword = encrypted
        // Primary (device): store the secret behind a Secure-Enclave biometric gate (so the
        // UserDefaults ciphertext alone is useless without a live biometric match). Also keep a legacy
        // ungated copy as a one-time fallback: it is deleted on the first *confirmed* biometric read
        // (see `readPassword`), so on a normal device it disappears at the very next unlock.
        if self.useSecureEnclaveGate {
            self.keyChainService.setBiometricSecret(key)
        } else {
            self.keyChainService.deleteBiometricSecret()
        }
        self.keyChainService.passwordKey = key
    }

    private func getBioSecAccessControl() -> SecAccessControl? {
        var error: Unmanaged<CFError>?
        let access: SecAccessControl? = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryCurrentSet,  &error)
        return access
    }

    private func checkBiometry(_ success: (() -> Void)?, _ failure: ((_ error: IError) -> Void)?) {
        let bioState = self.state
        guard bioState != .notAvailable else {
            STLogger.log(info: "biometric: checkBiometry failed — state .notAvailable (no enrolled biometrics / LAContext unavailable)")
            failure?(AuthError.stateNotAvailable)
            return
        }

        if bioState == .locked {
            let authContext = LAContext()
            authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: "", reply: { (successPolicy, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        failure?(AuthError.error(error: error))
                    } else {
                        success?()
                    }
                }
            })
        } else {
            success?()
        }
    }

    private func evaluateAccessControl(_ success: (() -> Void)?, _ failure:  ((_ error: IError) -> Void)?) {
        guard let accessControl = self.getBioSecAccessControl() else {
            STLogger.log(info: "biometric: evaluateAccessControl failed — could not create SecAccessControl")
            failure?(AuthError.unknown)
            return
        }
        let authContext = LAContext()
        authContext.evaluateAccessControl(accessControl, operation: .useItem, localizedReason: "unlock".localized) { (successPolicy, error) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let error = error {
                    STLogger.log(info: "biometric: evaluateAccessControl LAContext error — \(error.localizedDescription)")
                    failure?(AuthError.error(error: error))
                } else {
                    success?()
                }
            }
        }
    }

    private func unlockAppWithCheckin(_ success: @escaping (_ password: String) -> Void, _ failure:  @escaping (_ error: IError) -> Void) {
        // If a biometric-gated secret exists, the keychain read itself presents the biometric prompt,
        // so we go straight to `finishUnlock` (off the main thread — the read blocks while the prompt
        // is up and key derivation is CPU-heavy). Otherwise this is a legacy/first-run install with
        // only the ungated secret: use the decorative LAContext gate, then read + create on migration.
        if self.useSecureEnclaveGate && self.keyChainService.hasBiometricSecret() {
            self.finishUnlock(success, failure)
        } else {
            self.evaluateAccessControl({ [weak self] in
                self?.finishUnlock(success, failure)
            }, failure)
        }
    }

    private func finishUnlock(_ success: @escaping (_ password: String) -> Void, _ failure:  @escaping (_ error: IError) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            do {
                let password = try weakSelf.readPassword()
                try weakSelf.unlockApp(password: password)
                DispatchQueue.main.async {
                    success(password)
                }
            } catch {
                STLogger.log(info: "biometric: finishUnlock failed — \((error as? IError)?.message ?? "\(error)") (\(error))")
                DispatchQueue.main.async {
                    failure(error as? IError ?? AuthError.error(error: error))
                }
            }
        }
    }

    /// Whether the currently-stored biometric credential reproduces `password`, checked cheaply (no
    /// key derivation, no biometric prompt). For the Simulator/legacy path the ungated secret is
    /// verified directly; on device the gated secret can't be read without a prompt, so its mere
    /// presence is used (a genuinely mismatched gated secret is deleted in `readPassword`).
    private func storedCredentialMatches(password: String) -> Bool {
        guard let encryptedPassword = self.encryptedPassword else {
            return false
        }
        if self.useSecureEnclaveGate {
            return self.keyChainService.hasBiometricSecret()
        }
        guard let secret = self.keyChainService.passwordKey,
              let stored = STApplication.shared.crypto.decrypted(text: encryptedPassword, for: secret) else {
            return false
        }
        return stored == password
    }

    private func readPassword() throws -> String {
        guard STApplication.shared.dataBase.userProvider.user != nil else {
            throw AuthError.userNotFound
        }
        guard let encryptedPassword = self.encryptedPassword else {
            throw AuthError.userNotFound
        }

        // Preferred path (device only): a biometric-gated secret exists → require a live biometric
        // match. Skipped on the Simulator, which uses the legacy mechanism below.
        if self.useSecureEnclaveGate && self.keyChainService.hasBiometricSecret() {
            let context = LAContext()
            let result = self.keyChainService.biometricSecret(context: context, reason: "unlock".localized)
            if let secret = result.value {
                guard let password = STApplication.shared.crypto.decrypted(text: encryptedPassword, for: secret) else {
                    // The gated secret no longer matches the stored encrypted password (stale pair). It
                    // can never succeed — delete it and ask the user to re-auth once with the password.
                    self.keyChainService.deleteBiometricSecret()
                    throw AuthError.needsPasswordReauth
                }
                // The biometric read is confirmed working; now it is safe to drop any remaining legacy
                // ungated copy. From here on this device, unlock strictly requires biometrics.
                self.keyChainService.passwordKey = nil
                return password
            }
            // The biometric read failed. For an environment/availability failure fall back to the
            // legacy ungated secret IF it still exists (never lock the user out). Otherwise — whether a
            // user cancellation, a re-enrolled-biometrics invalidation, or a missing item — the path
            // forward is a one-time password login, so surface the descriptive re-auth error.
            let userBlocked = (result.status == errSecUserCanceled || result.status == errSecAuthFailed)
            if !userBlocked,
               let legacySecret = self.keyChainService.passwordKey,
               let password = STApplication.shared.crypto.decrypted(text: encryptedPassword, for: legacySecret) {
                return password
            }
            throw AuthError.needsPasswordReauth
        }

        // Legacy / first-run / Simulator path: only the ungated secret exists. The caller already
        // passed the decorative LAContext gate. Read it, then best-effort create the biometric-gated
        // item — but KEEP the legacy copy until a biometric read is confirmed (above), so a device that
        // can store but not read the gated item can never lock the user out.
        guard let legacySecret = self.keyChainService.passwordKey else {
            // Recovery for a half-migrated state (e.g. a prior build deleted the legacy secret but the
            // gated item can't be read here): try the gated item as a last resort.
            let context = LAContext()
            let result = self.keyChainService.biometricSecret(context: context, reason: "unlock".localized)
            if let secret = result.value,
               let password = STApplication.shared.crypto.decrypted(text: encryptedPassword, for: secret) {
                return password
            }
            throw AuthError.needsPasswordReauth
        }
        guard let password = STApplication.shared.crypto.decrypted(text: encryptedPassword, for: legacySecret) else {
            // The legacy secret no longer matches the stored encrypted password (e.g. UserDefaults and
            // the keychain fell out of sync across a reinstall / logout cycle). Delete the broken secret
            // so the next password unlock re-arms a consistent pair.
            self.keyChainService.passwordKey = nil
            throw AuthError.needsPasswordReauth
        }
        // Best-effort: create the biometric-gated item on device (kept alongside legacy until the first
        // confirmed gated read deletes it). On the Simulator the legacy secret remains authoritative.
        if self.useSecureEnclaveGate {
            self.keyChainService.setBiometricSecret(legacySecret)
        }
        return password
    }

}

public extension STBiometricAuthServices {

    var state: State {
        let authContext = LAContext()
        var error: NSError?
        let biometryAvailable = authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let laError = error as? LAError, laError.code == LAError.Code.biometryLockout {
            return .locked
        }
        return biometryAvailable ? .available : .notAvailable
    }

    var type: ServicesType {
        let authContext = LAContext()
        switch authContext.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            assert(true, "implement new type")
            return .none
        }
    }

    var canUnlockApp: Bool {
        guard self.state != .notAvailable else {
            return false
        }
        // Non-interactive: deciding whether to OFFER biometric unlock must not present a biometric
        // prompt or run key derivation. A credential exists if the encrypted password is present and
        // we have either the (preferred) biometric-gated secret or a not-yet-migrated legacy secret.
        guard self.encryptedPassword != nil else {
            return false
        }
        return self.keyChainService.hasBiometricSecret() || self.keyChainService.passwordKey != nil
    }

    /// Whether the user has enabled biometric unlock — independent of whether the
    /// credential is readable *right now*. Backed by the UserDefaults-stored
    /// encrypted password (available after first unlock), so unlike `canUnlockApp`
    /// it does not return `false` due to a transient keychain/file read failure
    /// right after a long device lock. Use this to decide whether to OFFER Face ID /
    /// Touch ID; the actual credential read still happens during the unlock attempt.
    var isBiometricConfigured: Bool {
        return self.state != .notAvailable && self.encryptedPassword != nil
    }

    func isValiedPassword(password: String) -> Bool {
        do {
           let _ = try STApplication.shared.crypto.getPrivateKey(password: password)
            return true
        } catch  {
            return false
        }
    }

    private var biometricAuthData: [String: Any]? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: self.userDefaultsKey)
        } get {
            return UserDefaults.standard.dictionary(forKey: self.userDefaultsKey) ?? [String: Any]()
        }
    }

    private var encryptedPassword: String? {
        set {
            self.biometricAuthData?[self.encryptedPasswordKey] = newValue
        } get {
            return self.biometricAuthData?[self.encryptedPasswordKey] as? String
        }
    }

}

public extension STBiometricAuthServices {

    enum State {
        case available
        case locked
        case notAvailable
    }

    enum ServicesType {
        case none
        case touchID
        case faceID
    }

    private enum AuthError: IError {

        case error(error: Error)
        case stateNotAvailable
        case unknown
        case userNotFound
        case passwordNotFound
        case decrypt
        case passwordNotValied
        case needsPasswordReauth

        var message: String {
            switch self {
            case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
                return error.localizedDescription
            case .stateNotAvailable:
                return "error_unknown_error".localized
            case .unknown:
                return "error_unknown_error".localized
            case .userNotFound:
                return "error_unknown_error".localized
            case .passwordNotFound:
                return "error_unknown_error".localized
            case .decrypt:
                return "error_unknown_error".localized
            case .passwordNotValied:
                return "error_password_not_valed".localized
            case .needsPasswordReauth:
                return "biometric_needs_password_reauth".localized
            }
        }
    }

}
