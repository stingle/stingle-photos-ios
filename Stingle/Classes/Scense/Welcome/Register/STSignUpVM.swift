import Foundation
import Foundation

class STSignUpVM {
	
	let authWorker = STAuthWorker()
	let validator = STValidator()
	
	func registr(email: String?, password: String?, confirmPassword: String?, includePrivateKey: Bool, success: @escaping ((_ result: STAuth.Register) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
		do {
			let email = try self.validator.validate(email: email)
			let password = try self.validator.validate(password: password)
			guard  password == confirmPassword else {
				failure(SignUpVMError.confirmPassword)
				return
			}
			self.registr(email: email, password: password, includePrivateKey: includePrivateKey, success: success, failure: failure)
		} catch {
			failure(error as! IError)
		}
	}
	
	//MARK: - Private funcs
	
	private func validateEmail(email: String) -> Bool {
		return true
	}
	
	private func validatePassord(email: String) -> Bool {
		return true
	}
	
	private func registr(email: String, password: String, includePrivateKey: Bool, success: @escaping ((_ result: STAuth.Register) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
		self.authWorker.register(email: email, password: password, includePrivateKey: includePrivateKey, success: success, failure: failure)
	}
	
}

extension STSignUpVM {
	
	private enum SignUpVMError: IError {
		case confirmPassword
		var message: String {
			switch self {
			case .confirmPassword:
				return "error_incorrect_confirm_password".localized
			}
		}
	}
	
}
