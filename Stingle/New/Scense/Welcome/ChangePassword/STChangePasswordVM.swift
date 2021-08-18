//
//  STChangePasswordVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/29/21.
//

import Foundation

class STChangePasswordVM {
    
    private let validator = STValidator()
    private let authWorker = STAuthWorker()
    
    func changePassword(oldPassword: String?, newPassword: String?, confirmPassword: String?, completion: @escaping (IError?) -> Void) {
        
        do {
            let password = try self.validate(oldPassword: oldPassword, newPassword: newPassword, confirmPassword: confirmPassword)
            
            self.authWorker.resetPassword(oldPassword: password.oldPassword, newPassword: password.newPassword) { _ in
                completion(nil)
            } failure: { errno in
                completion(errno)
            }
            
        } catch {
            completion(STError.error(error: error))
        }
                
    }
    
    //MARK: - Private methods
    
    private func validate(oldPassword: String?, newPassword: String?, confirmPassword: String?) throws -> (oldPassword: String, newPassword: String) {
        
        guard let oldPassword = oldPassword else {
            throw ChangePasswordError.emptyPassword
        }
        
        guard ((try? STApplication.shared.crypto.getPrivateKey(password: oldPassword)) != nil) else {
            throw ChangePasswordError.passwordIncorrect
        }
        
        let newPassword = try self.validator.validate(password: newPassword)
        
        guard newPassword == confirmPassword else {
            throw ChangePasswordError.confirmPassword
        }
        
        guard newPassword != oldPassword else {
            throw ChangePasswordError.machingPasswords
        }
        
        return (oldPassword, newPassword)
    }
    
}

extension STChangePasswordVM {
    
    private enum ChangePasswordError: IError {
        
        case confirmPassword
        case emptyEmail
        case emptyPassword
        case passwordIncorrect
        case machingPasswords
        
        var message: String {
            switch self {
            case .confirmPassword:
                return "error_incorrect_confirm_password".localized
            case .emptyEmail:
                return "error_incorrect_email".localized
            case .emptyPassword:
                return "error_password_not_valed".localized
            case .passwordIncorrect:
                return "error_password_not_valed".localized
            case .machingPasswords:
                return "error_maching_passwords".localized
            }
        }
        
    }
    
}
