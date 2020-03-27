import Foundation
import CoreData

class AppInfo {
	var lastSeen:UInt64
	var lastDelSeen:UInt64
	var spaceUsed:String
	var spaceQuota:String
	
	init(info:AppInfoMO) {
		lastSeen = info.lastSeen
		lastDelSeen = info.lastDelSeen
		spaceQuota = info.spaceQuota
		spaceUsed = info.spaceUsed
	}
	
	init(lastSeen:UInt64, lastDelSeen:UInt64, spaceQuota:String, spaceUsed:String) {
		self.lastSeen = lastSeen
		self.lastDelSeen = lastDelSeen
		self.spaceUsed = spaceUsed
		self.spaceQuota = spaceQuota
	}
}

class AppInfoMO: NSManagedObject {
	@NSManaged var lastSeen:UInt64
	@NSManaged var lastDelSeen:UInt64
	@NSManaged var spaceUsed:String
	@NSManaged var spaceQuota:String
	
	func update(lastSeen:UInt64, lastDelSeen:UInt64, spaceQuota:String, spaceUsed:String) {
		self.lastSeen = lastSeen
		self.lastDelSeen = lastDelSeen
		self.spaceUsed = spaceUsed
		self.spaceQuota = spaceQuota
	}
}
