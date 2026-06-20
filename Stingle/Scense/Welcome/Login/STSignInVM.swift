import Foundation
import StingleRoot

class STSignInVM {
	
	private let authWorker = STAuthWorker()
	private let validator = STValidator()
    
    private var user: STUser?
	
    func login(email: String?, password: String?, success: @escaping ((_ result: STUser, _ appPassword: String) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
		do {
			let validEmail = try self.validator.validate(email: email)
			let validPassword = try self.validator.validate(password: password, withCharacters: false)
			self.login(email: validEmail, password: validPassword, success: success, failure: failure)
		} catch {
			failure((error as? IError) ?? STSignInVM.SignInError.incorrectPassword)
		}
	}
    
    func checkRecoveryPhrase(phrase: String?, password: String?, compliation: @escaping ((_ error: IError?) -> Void)) {
        guard let phrase = phrase, !phrase.isEmpty else {
            compliation(SignInError.incorrectPhrase)
            return
        }
        
        guard let user = self.user else {
            compliation(SignInError.userNotFound)
            return
        }
        
        guard let password = password, !password.isEmpty else {
            compliation(SignInError.incorrectPassword)
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.authWorker.checkRecoveryPhraseAfterLogin(user: user, phrase: phrase, password: password)
                compliation(nil)
            } catch {
                compliation((error as? IError) ?? STError.error(error: error))
            }
        }
    }
	
	//MARK: - Private funcs
	
	private func login(email: String, password: String, success: @escaping ((_ result: STUser, _ appPassword: String) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let user = try await self.authWorker.login(email: email, password: password)
                self.user = user
                success(user, password)
            } catch {
                failure((error as? IError) ?? STError.error(error: error))
            }
        }
	}
    	
}

extension STSignInVM {
    
    enum SignInError: IError {
        
        case userNotFound
        case incorrectPhrase
        case incorrectPassword
        
        var message: String {
            switch self {
            case .userNotFound:
                return "error_data_not_found".localized
            case .incorrectPhrase:
                return "error_incorrect_phrase".localized
            case .incorrectPassword:
                return "error_password_not_valed".localized
            }
        }
        
    }
    
}
