//
//  STUnlockAppVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/22/21.
//

import Foundation

class STUnlockAppVM {
    
    private var appBiometricResultPassword: String?
    
    lazy var biometric: STBiometricAuthServices = {
        return STBiometricAuthServices()
    }()
    
    var canUnlockAppBiometric: Bool {
        return self.biometric.canUnlockApp
    }
    
    func unlockAppBiometric(success: @escaping (_ confirmpassword: Bool) -> Void, failure: @escaping (IError?) -> Void) {
        let comfirmPassword = STAppSettings.security.authentication.requireConfirmation
        self.biometric.unlockApp { [weak self] password in
            self?.appBiometricResultPassword = password
            success(comfirmPassword)
        } failure: { error in
            failure(error)
        }
    }
    
    func confirmBiometricPassword(password: String?) throws {
        guard let password = password, !password.isEmpty else {
            throw UnlockAppVMError.passwordIsNil
        }
        if password != self.appBiometricResultPassword  {
            throw UnlockAppVMError.passwordIncorrect
        }
    }
    
    func unlockApp(password: String?, completion: @escaping (IError?) -> Void) {
        guard let password = password, !password.isEmpty else {
            completion(UnlockAppVMError.passwordIsNil)
            return
        }
        do {
            try self.biometric.unlockApp(password: password)
            completion(nil)
        } catch {
            completion(UnlockAppVMError.passwordIncorrect)
        }
    }
    
    func logOutApp() {
        STApplication.shared.logout()
    }
    
}

extension STUnlockAppVM {

    private enum UnlockAppVMError: IError {
        
        case passwordIsNil
        case passwordIncorrect
        
        var message: String {
            switch self {
            case .passwordIsNil:
                return "error_empty_password".localized
            case .passwordIncorrect:
                return "error_password_not_valed".localized
            }
        }
        
    }
    
}
