import Foundation
import Foundation
import StingleRoot

class STSignUpVM {
	
	private let authWorker = STAuthWorker()
	private let validator = STValidator()
	
    func registr(email: String?, password: String?, confirmPassword: String?, includePrivateKey: Bool, success: @escaping ((_ result: STUser, _ password: String) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
		do {
			let email = try self.validator.validate(email: email)
            let password = try self.validator.validate(password: password, confirmPassword: confirmPassword)
			self.registr(email: email, password: password, includePrivateKey: includePrivateKey, success: success, failure: failure)
		} catch {
			failure(error as! IError)
		}
	}
	
	//MARK: - Private fupasswordncs

    private func registr(email: String, password: String, includePrivateKey: Bool, success: @escaping ((_ result: STUser, _ password: String) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
        self.authWorker.registerAndLogin(email: email, password: password, includePrivateKey: includePrivateKey, success: { user in
            success(user, password)
        }, failure: failure)
        
	}
	
}
