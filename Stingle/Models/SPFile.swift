import Foundation
import CoreData

//MARK : Core Data Managed Objects
class FileMO : NSManagedObject {
	@NSManaged var dateCreated:String?
	@NSManaged var dateModified:String?
	@NSManaged var name:String
	@NSManaged var headers:String?
	@NSManaged var version:String?
	@NSManaged var isLocal:Bool
	@NSManaged var isRemote:Bool
	@NSManaged var reUpload:Int
	@NSManaged var date:Date
	
	func update(file:SPFileInfo) {
		dateCreated = file.dateCreated
		dateModified = file.dateModified
		name = file.name
		headers = file.headers
		version = file.version
		let cut = 24 * 3600 * 1000
		let back = 24 * 3600
		let timeInterval = (((dateCreated ?? "0") as NSString).integerValue / cut) * back
		date = Date(timeIntervalSince1970: Double(timeInterval))
		isLocal = file.isLocal ?? true
		isRemote = file.isRemote ?? true
		reUpload = file.reUpload ?? 0
	}
}

class TrashMO : FileMO {
	
}

class DeletedFileMO : NSManagedObject {
	@NSManaged var date:Date
	@NSManaged var name:String
	@NSManaged var type:Int
	
	func update(info:SPDeletedFile) {
		let timeInterval = (info.date as NSString).integerValue / 1000
		date = Date(timeIntervalSince1970: Double(timeInterval))
		name = info.name
		type = info.type
	}
}

class SPFileInfo : Codable {
	
	var dateCreated:String
	var dateModified:String
	var name:String
	var headers:String
	var version:String
	var isLocal:Bool?
	var isRemote:Bool?
	var reUpload:Int?
	var date:Date?
	var type:Int?
	var duration:Int?

	
	class func mo() -> String {
		fatalError()
	}
	
	required init(file:FileMO) {
		dateCreated = file.dateCreated ?? ""
		dateModified = file.dateModified ?? ""
		name = file.name
		headers = file.headers ?? ""
		version = file.version ?? ""
		isLocal = file.isLocal
		isRemote = file.isRemote
		reUpload = file.reUpload
		date = file.date
	}
	
	enum CodingKeys : String, CodingKey {
		case dateCreated
		case dateModified
		case name = "file"
		case headers
		case version
	}
}

class SPFile: SPFileInfo {
	override class func mo() -> String {
		return "Files"
	}
}

class SPTrashFile : SPFileInfo {
	override class func mo() -> String {
		return "Trash"
	}
}


class SPDeletedFile: Codable {
	
	var date:String
	var name:String
	var type:Int
	
	required init(file: FileMO) {
		type = 1
		date = "\(file.date.timeIntervalSince1970)"
		name = file.name
	}
	
	enum CodingKeys : String, CodingKey {
		case date
		case name = "file"
		case type
	}


	
	func mo() -> String {
		return "Deletes"
	}

}
