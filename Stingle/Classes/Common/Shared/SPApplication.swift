import Foundation

class SPApplication {
	
	public static let sync = SyncManager()
	public static let crypto = Crypto()
	public static var user = User.shared
	
	static func isLogedIn () -> Bool {
		do {
			let db = try DataBase.shared()
			guard let userId = db.getUserId() else {
				return false
			}
			return userId >= 0
		} catch {
			print(error)
			return false
		}
	}
	
	static func isLocked() -> Bool {
		return nil == KeyManagement.key
	}
		
	static func lock() {
		KeyManagement.key = nil
	}
	
	static func unLock(with password:String) throws {
		let key = try crypto.getPrivateKey(password: password)
		KeyManagement.key = key
	}

}
