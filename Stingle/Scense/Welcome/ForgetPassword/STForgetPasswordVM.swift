//
//  STForgetPasswordVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/18/21.
//

import UIKit
import StingleRoot

class STForgetPasswordVM {
    
    private let authWorker = STAuthWorker()
    private let validator = STValidator()
    private var recoveryPhraseResponse: STAuthWorker.RecoveryPhraseResponse?

    func checkPhrase(email: String?, phrase: String?, completion: @escaping ((IError?) -> Void)) {
        guard let email = email, !email.isEmpty else {
            completion(ForgetPasswordError.emptyEmail)
            return
        }
        guard let phrase = phrase, !phrase.isEmpty else {
            completion(ForgetPasswordError.incorrectPhrase)
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let response = try await self.authWorker.checkRecoveryPhrase(email: email, phrase: phrase)
                self.recoveryPhraseResponse = response
                completion(nil)
            } catch {
                completion((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func recoverAccount(email: String?, newPassword: String?, confirmPassword: String?, success: @escaping ((_ password: String) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
        do {
            guard let email = email, !email.isEmpty else {
                failure(ForgetPasswordError.emptyEmail)
                return
            }
            guard let phraseResponse = recoveryPhraseResponse else {
                failure(STError.unknown)
                return
            }
            let password = try self.validator.validate(password: newPassword, confirmPassword: confirmPassword)
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    _ = try await self.authWorker.recoverAccount(email: email, password: password, phraseResponse: phraseResponse)
                    success(password)
                } catch {
                    failure((error as? IError) ?? STError.error(error: error))
                }
            }
        } catch {
            failure(STError.error(error: error))
        }
    }
}

extension STForgetPasswordVM {
    
    private enum ForgetPasswordError: IError {
        
        case confirmPassword
        case emptyEmail
        case emptyPassword
        case passwordIncorrect
        case machingPasswords
        case incorrectPhrase
        
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
            case .incorrectPhrase:
                return "error_incorrect_phrase".localized
            }
        }
        
    }
    
}
