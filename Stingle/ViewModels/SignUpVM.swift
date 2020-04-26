import Foundation
import Foundation

class SignUpVM: NSObject {
	private let crypto:Crypto = Crypto()

	public func signUp(email:String?, password:String?, completionHandler: @escaping (Bool, Error?) -> Swift.Void) -> Bool {
		return SyncManager.signUp(email: email, password: password, completionHandler: completionHandler)
	}

	private func validateEmail(email:String) -> Bool{
		return true
	}
	
	private func validatePassord(email:String) -> Bool{
		return true
	}
	
}
