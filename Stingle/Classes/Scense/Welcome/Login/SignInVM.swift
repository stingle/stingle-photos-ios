import Foundation

class SignInVM {
	
	private let authWorker = STAuthWorker()
	private let validator = STValidator()
	
	func login(email: String?, password: String?, success: @escaping ((_ result: User) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
//		let email = "alex1@stingle.org"
//		let password = "123456"
		do {
			let validEmail = try self.validator.validate(email: email)
			let validPassword = try self.validator.validate(password: password)
			self.login(email: validEmail, password: validPassword, success: success, failure: failure)
		} catch {
			failure(error as! IError)
		}
	}
	
	//MARK: - Private funcs
	
	private func login(email: String, password: String, success: @escaping ((_ result: User) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
		self.authWorker.login(email: email, password: password, success: success, failure: failure)
	}
	
}
