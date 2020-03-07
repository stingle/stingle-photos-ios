import Foundation
import CoreData

class AppInfo {
	var lastSeen:UInt64
	var lastDelSeen:UInt64
	
	init(info:AppInfoMO) {
		lastSeen = info.lastSeen
		lastDelSeen = info.lastDelSeen
	}
	
	init(lastSeen:UInt64, lastDelSeen:UInt64) {
		self.lastSeen = lastSeen
		self.lastDelSeen = lastDelSeen
	}
}

class AppInfoMO: NSManagedObject {
	@NSManaged var lastSeen:UInt64
	@NSManaged var lastDelSeen:UInt64
	
	func update(lastSeen:UInt64, lastDelSeen:UInt64) {
		self.lastSeen = lastSeen
		self.lastDelSeen = lastDelSeen
	}
}
