import Foundation

class User {
	
	static private var shared:User? = nil
	
	public let token:String
	public let userId:String
	public let isKeyBackedUp:Bool
	public let homeFolder:String
	
	private var secret:[UInt8] = []
	
	//TODO : maybe KayChain is better place to store the secret
	public var key:[UInt8] { get { return secret } set(newKey) { secret = newKey } }
	
	private init() {
		token = ""
		userId = ""
		isKeyBackedUp = false
		homeFolder = ""
	}
	
	//TODO: Create propper singletone
	init(response:SPSignInResponse) {
		if User.shared != nil {
			fatalError()
		}
		token = response.parts.token
		userId = response.parts.userId
		isKeyBackedUp = (response.parts.isKeyBackedUp == 1)
		homeFolder = response.parts.homeFolder
		User.shared = self
	}
	
	public func get() -> User {
		return User.shared!
	}
	
	static public func autorized() -> Bool {
		return false
	}
}
