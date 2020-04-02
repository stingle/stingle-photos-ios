import Foundation

class SPApplication {
	public static let sync = SyncManager()
	public static let crypto = Crypto()
	public static var user:User?
}
