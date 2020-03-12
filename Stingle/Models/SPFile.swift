import Foundation
import CoreData

//MARK : Core Data Managed Objects
class FileMO : NSManagedObject {
	@NSManaged var dateCreated:String?
	@NSManaged var dateModified:String?
	@NSManaged var file:String
	@NSManaged var headers:String?
	@NSManaged var version:String?
	@NSManaged var isLocal:Bool
	@NSManaged var reUpload:Int
	@NSManaged var date:Date
	
	func update(file:SPFile) {
		dateCreated = file.dateCreated
		dateModified = file.dateModified
		self.file = file.file
		headers = file.headers
		version = file.version
		let cut = 24 * 3600 * 1000
		let back = 24 * 3600
		let timeInterval = (((dateCreated ?? "0") as NSString).integerValue / cut) * back
		date = Date(timeIntervalSince1970: Double(timeInterval))
		guard let newIsLocal = file.isLocal, let newReUpload = file.reUpload else {
			return
		}
		isLocal = newIsLocal
		reUpload = newReUpload
	}
}

class TarshMO : FileMO {
	
}

class DeletedFileMO : NSManagedObject {
	@NSManaged var date:Int64
	@NSManaged var file:String
	@NSManaged var type:Int
	
	func update(info:SPDeletedFile) {
		if let intDate = Int64(info.date) {
			date = intDate
		} else {
			date = 0
		}
		file = info.file
		type = info.type
	}
}

//MARK : Codable(serializable) objects 
protocol SPFileInfo : Codable {
	func mo() -> String
}

class SPFile: SPFileInfo {
	var dateCreated:String
	var dateModified:String
	var file:String
	var headers:String
	var version:String
	var isLocal:Bool?
	var reUpload:Int?
	var date:Date?
	
	func mo() -> String {
		return "Files"
	}
	
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
		self.file = file.file 
		headers = file.headers ?? ""
		version = file.version ?? ""
		isLocal = file.isLocal
		reUpload = file.reUpload
		date = file.date
	}
}

class SPTrashFile : SPFile {
	override func mo() -> String {
		return "Trash"
	}
}

class SPDeletedFile: SPFileInfo {
	var date:String
	var file:String
	var type:Int
	
	func mo() -> String {
		return "Deletes"
	}

}

