import Foundation

class SignInVM: NSObject {
	private let crypto:Crypto = Crypto()
	
	public func signIn(email:String?, password:String?, completionHandler: @escaping (Bool, Error?) -> Swift.Void) -> Bool {
		guard let email = email, let password = password else {
			return false
		}
		
		let request = SPPreSignInRequest(email: email)
		_ = NetworkManager.send(request:request) { (data:SPPreSignInResponse?, error)  in do {
			guard let data = data, error == nil else {
				completionHandler(false, error)
				return
			}
			let pHash = try self.crypto.getPasswordHashForStorage(password: password, salt: data.parts.salt)
			let request = SPSignInRequest(email: email, password: pHash)
			_ = NetworkManager.send(request: request) { (data:SPSignInResponse?, error) in do {
				guard let data = data, error == nil else {
					completionHandler(false, error)
					return
				}
				let isKeyBackedUp:Bool = (data.parts.isKeyBackedUp == 1)
				SPApplication.user = User(token: data.parts.token, userId: data.parts.userId, isKeyBackedUp: isKeyBackedUp, homeFolder: data.parts.homeFolder, email: email)
				guard true == KeyManagement.importKeyBundle(keyBundle: data.parts.keyBundle, password: password) else {
					print("Can't import key bundle")
					return
				}
				KeyManagement.key = try self.crypto.getPrivateKey(password: password)
				let pubKey = data.parts.serverPublicKey
				KeyManagement.importServerPublicKey(pbk: pubKey)
				completionHandler(true, nil)
			} catch {
				completionHandler(false, error)
				}
			}
		} catch {
			completionHandler(false, error)
			}
		}
		return false
	}
	
	private func validateEmail(email:String) -> Bool{
		return true
	}
	
	private func validatePassord(email:String) -> Bool{
		return true
	}
	
}
