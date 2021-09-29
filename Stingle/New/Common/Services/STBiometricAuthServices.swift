//
//  STBiometricAuthenticationServices.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/20/21.
//

import LocalAuthentication

class STBiometricAuthServices {
    
    private let keyChainService = STKeyChainService()
    private let userDefaultsKey = "biometricAuthDatakey"
    private let encryptedPasswordKey = "encryptedPasswordKey"
    
    //MARK: - Public methods
    
    func removeBiometricAuth() {
        self.keyChainService.passwordKey = nil
        self.encryptedPassword = nil
    }
    
    func onBiometricAuth(password: String, _ success: ( () -> Void)? = nil, failure:  ((_ error: IError) -> Void)? = nil) {
        do {
            try self.setApp(password: password)
            success?()
        } catch {
            failure?(AuthError.error(error: error))
        }
    }
    
    func unlockApp(_ success: @escaping (_ password: String) -> Void, failure:  @escaping (_ error: IError) -> Void) {
        self.checkBiometry({ [weak self] in
            self?.unlockAppWithCheckin(success, failure)
        }, failure)
    }
    
    func unlockApp(password: String) throws {
        let key = try STApplication.shared.crypto.getPrivateKey(password: password)
        STKeyManagement.key = key
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
            failure?(AuthError.unknown)
            return
        }
        let authContext = LAContext()
        authContext.evaluateAccessControl(accessControl, operation: .useItem, localizedReason: "unlock".localized) { (successPolicy, error) in
            DispatchQueue.main.async {
                if let error = error {
                    failure?(AuthError.error(error: error))
                } else {
                    success?()
                }
            }
        }
    }
        
    private func unlockAppWithCheckin(_ success: @escaping (_ password: String) -> Void, _ failure:  @escaping (_ error: IError) -> Void) {
        self.evaluateAccessControl({ [weak self] in
            guard let weakSelf = self else {
                return
            }
            do {
                let password = try weakSelf.unlockApp()
                success(password)
            } catch {
                failure(AuthError.error(error: error))
            }
        }, failure)
    }
    
    private func unlockApp() throws -> String {
        let password = try self.readPassword()
        try self.unlockApp(password: password)
        return password
    }
        
    private func readPassword() throws -> String {
        guard STApplication.shared.dataBase.userProvider.user != nil else {
            throw AuthError.userNotFound
        }
        guard let passwordKey = self.keyChainService.passwordKey, let encryptedPassword = self.encryptedPassword else {
            throw AuthError.userNotFound
        }
        guard let password = STApplication.shared.crypto.decrypted(text: encryptedPassword, for: passwordKey) else {
            throw AuthError.userNotFound
        }
        return password
    }
    
}

extension STBiometricAuthServices {
    
    var state: State {
        let authContext = LAContext()
        var error: NSError?
        let biometryAvailable = authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let laError = error as? LAError, laError.code == LAError.Code.biometryLockout {
            return .locked
        }
        return biometryAvailable ? .available : .notAvailable
    }
    
    var type: Type {
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
        do {
            let password = try self.readPassword()
            let _ = try STApplication.shared.crypto.getPrivateKey(password: password)
            return true
        } catch {
            return false
        }
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


extension STBiometricAuthServices {
    
    
    enum State {
        case available
        case locked
        case notAvailable
    }
    
    enum `Type` {
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
            }
        }
    }
    
}
