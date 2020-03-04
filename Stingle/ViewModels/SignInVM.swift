import Foundation

class SignInVM: NSObject {
    private let crypto:Crypto = Crypto()

	public func signIn(email:String?, password:String?) -> Bool {
		guard let email = email, let password = password else {
			return false
		}
		
		let request = SPPreSignInRequest(email: email)
		let task = NetworkManager.send(request:request) { (data:SPPreSignInResponse) in
			do {
				let pHash = try self.crypto.getPasswordHashForStorage(password: password, salt: data.parts.salt)
				let request = SPSignInRequest(email: email, password: pHash)
				let task = NetworkManager.send(request: request) { (data:SPSignInResponse) in
					do {
						let user = User(response: data)
						user.key = try self.crypto.getPrivateKey(password: password)
						print(data)
					} catch {
						print(error)
					}
				}
				print(task.taskIdentifier)
			} catch {
				print(error)
			}
			
		}
		print(task.taskIdentifier)
		return false
	}
	
	private func validateEmail(email:String) -> Bool{
		return true
	}
	
	private func validatePassord(email:String) -> Bool{
		return true
	}

}
