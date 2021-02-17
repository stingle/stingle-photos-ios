import Foundation
import CoreData

class AppInfo {
	var lastSeen:UInt64
	var lastDelSeen:UInt64
	var spaceUsed:String
	var spaceQuota:String
	var userId:Int?
	
	init(info:AppInfoMO) {
		lastSeen = info.lastSeen
		lastDelSeen = info.lastDelSeen
		spaceQuota = info.spaceQuota
		spaceUsed = info.spaceUsed
		userId = info.userId
	}
	
	init(lastSeen:UInt64, lastDelSeen:UInt64, spaceQuota:String, spaceUsed:String, userId:Int) {
		self.lastSeen = lastSeen
		self.lastDelSeen = lastDelSeen
		self.spaceUsed = spaceUsed
		self.spaceQuota = spaceQuota
		self.userId = userId
	}
}

class AppInfoMO: NSManagedObject {
	@NSManaged var lastSeen:UInt64
	@NSManaged var lastDelSeen:UInt64
	@NSManaged var spaceUsed:String
	@NSManaged var spaceQuota:String
	@NSManaged var userId:Int
	
	func update(lastSeen:UInt64, lastDelSeen:UInt64, spaceQuota:String, spaceUsed:String, userId:Int) {
		self.lastSeen = lastSeen
		self.lastDelSeen = lastDelSeen
		self.spaceUsed = spaceUsed
		self.spaceQuota = spaceQuota
		self.userId = userId
	}
}
