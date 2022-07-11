//
//  STSecurityVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/15/21.
//

import Foundation
import StingleRoot

class STSecurityVM {
        
    lazy var security: STAppSettings.Security = {
        return STAppSettings.current.security
    }()
    
    lazy var biometric: STBiometricAuthServices = {
        return STBiometricAuthServices()
    }()
    
    lazy var validator: STValidator = {
        return STValidator()
    }()
    
    func removeBiometricAuthentication() {
        self.biometric.removeBiometricAuth()
        self.security.authentication.unlock = true
        STAppSettings.current.security = self.security
    }
    
    func add(biometricAuthentication password: String, completion: @escaping (IError?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.biometric.onBiometricAuth(password: password) {
                weakSelf.security.authentication.unlock = true
                STAppSettings.current.security.authentication.unlock = true
                completion(nil)
            } failure: { error in
                completion(error)
            }
        }
    }
    
    func update(lockUpApp: STAppSettings.Security.LockUpApp) {
        self.security.lockUpApp = lockUpApp
        STAppSettings.current.security = self.security
    }
    
}
