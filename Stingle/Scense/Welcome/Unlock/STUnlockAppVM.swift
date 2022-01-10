//
//  STUnlockAppVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/22/21.
//

import Foundation

class STUnlockAppVM {
    
    lazy var unlocker: STAppLockUnlocker.UnLocker = {
        return STAppLockUnlocker().unLocker
    }()
    
    var biometricAuthServicesType: STBiometricAuthServices.ServicesType {
        return self.unlocker.biometricAuthServicesType
    }
    
    var canUnlockAppBiometric: Bool {
        return self.unlocker.canUnlockAppBiometric
    }
    
    func unlockAppBiometric(success: @escaping () -> Void, failure: @escaping (IError?) -> Void) {
        self.unlocker.unlockAppBiometric(success: success, failure: failure)
    }
    
    func confirmBiometricPassword(password: String?) throws {
        guard let password = password, !password.isEmpty else {
            throw UnlockAppVMError.passwordIsNil
        }
    }
    
    func unlockApp(password: String?, completion: @escaping (IError?) -> Void) {
        guard let password = password, !password.isEmpty else {
            completion(UnlockAppVMError.passwordIsNil)
            return
        }
        self.unlocker.unlockApp(password: password, completion: completion)
    }
    
    func logOutApp() {
        STApplication.shared.utils.logout()
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
