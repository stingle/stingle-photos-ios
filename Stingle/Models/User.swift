import Foundation

class User {
	
	static private var shared:User? = nil
	public let token:String
	public let userId:String
	public let isKeyBackedUp:Bool
	public let homeFolder:String
	public let email:String
		
	init(token:String, userId:String, isKeyBackedUp:Bool, homeFolder:String, email:String) {
		self.token = token
		self.userId = userId
		self.isKeyBackedUp = isKeyBackedUp
		self.homeFolder = homeFolder
		self.email = email
		if(User.shared == nil) {
			User.shared = self
		}
	}
		
	static public func get() -> User? {
		return User.shared
	}	
}
