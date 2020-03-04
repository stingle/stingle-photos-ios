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
						let isKeyBackedUp:Bool = (data.parts.isKeyBackedUp == 1)
						SPApplication.user = User(token: data.parts.token, userId: data.parts.userId, isKeyBackedUp: isKeyBackedUp, homeFolder: data.parts.homeFolder, email: email)
						guard true == KeyManagement.importKeyBundle(keyBundle: data.parts.keyBundle, password: password) else {
							print("Can't import key bundle")
							return
						}
						KeyManagement.key = try self.crypto.getPrivateKey(password: password)
						print(data)
					} catch {
						print(error)
						return
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
