import Foundation
import Foundation

class SignUpVM: NSObject {
	private let crypto:Crypto = Crypto()

	public func signUp(email:String?, password:String?, completionHandler: @escaping (Bool, Error?) -> Swift.Void) -> Bool {
		guard let email = email, let password = password else {
			return false
		}
		var request:SPSignUpRequest? = nil
		do {
			try crypto.generateMainKeypair(password: password)
			guard let pwdHash = try crypto.getPasswordHashForStorage(password: password) else {
				completionHandler(false, nil)
				return false
			}
			guard let salt = pwdHash["salt"] else {
				completionHandler(false, nil)
				return false
			}
			guard let pwd = pwdHash["hash"] else {
				completionHandler(false, nil)
				return false
			}
			guard let keyBundle = try KeyManagement.getUploadKeyBundle(password: password, includePrivateKey: true) else {
				completionHandler(false, nil)
				return false
			}
			request = SPSignUpRequest(email: email, password: pwd, salt: salt, keyBundle: keyBundle, isBackup: true)

		} catch {
			completionHandler(false, error)
			return false
		}
		guard let signUpRequest = request else {
			completionHandler(false, nil)
			return false
		}
		_ = NetworkManager.send(request:signUpRequest) { (data:SPPreSignInResponse?, error)  in
			guard let data = data, error == nil else {
				completionHandler(false, error)
				return
			}
		}
		return true
	}
	
	private func validateEmail(email:String) -> Bool{
		return true
	}
	
	private func validatePassord(email:String) -> Bool{
		return true
	}
	
}
