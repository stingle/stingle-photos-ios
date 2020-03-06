import Foundation
import CoreData

class FileMO : NSManagedObject {
	@NSManaged var dateCreated:String?
	@NSManaged var dateModified:String?
	@NSManaged var file:String?
	@NSManaged var headers:String?
	@NSManaged var version:String?
	@NSManaged var isLocal:Bool
	@NSManaged var reUpload:Int
	
	func update(file:SPFile) {
		dateCreated = file.dateCreated
		dateModified = file.dateModified
		self.file = file.file
		headers = file.headers
		version = file.version
		guard let newIsLocal = file.isLocal, let newReUpload = file.reUpload else {
			return
		}
		isLocal = newIsLocal
		reUpload = newReUpload
	}
}


struct SPFile: Codable {
	var dateCreated:String
	var dateModified:String
	var file:String
	var headers:String
	var version:String
	var isLocal:Bool?
	var reUpload:Int?
	
	enum CodingKeys : CodingKey {
		case dateCreated
		case dateModified
		case file
		case headers
		case version
	}
	
	init(file:FileMO) {
		dateCreated = file.dateCreated ?? ""
		dateModified = file.dateModified ?? ""
		self.file = file.file ?? ""
		headers = file.headers ?? ""
		version = file.version ?? ""
		isLocal = file.isLocal
		reUpload = file.reUpload
	}
}
