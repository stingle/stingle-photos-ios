import Foundation
import CoreData

class User {
	static public var shared:User? = {
		if let user = User.current {
			return user
		}
		do {
			let db = try DataBase.shared()
			guard let userId = db.getUserId(), userId >= 0 else {
				return nil
			}
			User.current = db.getUser(userId: userId)
			return User.current
		} catch {
			print(error)
			return nil
		}
	}()
	
	static private var current:User?
	
	public var token:String
	public let userId:Int
	public let isKeyBackedUp:Bool
	public let homeFolder:String
	public let email:String
		
	init(token:String, userId:Int, isKeyBackedUp:Bool, homeFolder:String, email:String) {
		self.token = token
		self.userId = userId
		self.isKeyBackedUp = isKeyBackedUp
		self.homeFolder = homeFolder
		self.email = email
		if(User.shared == nil) {
			User.shared = self
		}
	}
	
	init(mo:UserMO) {
		self.token = mo.token
		self.userId = mo.userId
		self.isKeyBackedUp = mo.isKeyBackedUp
		self.homeFolder = mo.homeFolder
		self.email = mo.email
	}
}

class UserMO: NSManagedObject {
	
	@NSManaged var token:String
	@NSManaged var userId:Int
	@NSManaged var isKeyBackedUp:Bool
	@NSManaged var homeFolder:String
	@NSManaged var email:String
	
	func update(user:User) {
		token = user.token
		userId = user.userId
		isKeyBackedUp = user.isKeyBackedUp
		homeFolder = user.homeFolder
		email = user.email
	}
}
