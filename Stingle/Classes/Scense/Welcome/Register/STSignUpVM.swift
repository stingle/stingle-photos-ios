import Foundation
import Foundation

class STSignUpVM {
	
	private let authWorker = STAuthWorker()
	private let validator = STValidator()
	
	func registr(email: String?, password: String?, confirmPassword: String?, includePrivateKey: Bool, success: @escaping ((_ result: User) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
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

	private func registr(email: String, password: String, includePrivateKey: Bool, success: @escaping ((_ result: User) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
		self.authWorker.registerAndLogin(email: email, password: password, includePrivateKey: includePrivateKey, success: success, failure: failure)
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
