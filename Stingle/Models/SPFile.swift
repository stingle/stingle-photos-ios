import Foundation
import CoreData
import Photos

//MARK : Core Data Managed Objects
class FileMO : NSManagedObject {
	@NSManaged var dateCreated:String
	@NSManaged var dateModified:String
	@NSManaged var name:String
	@NSManaged var type:Int
	@NSManaged var headers:String
	@NSManaged var duration:UInt32
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
		let timeInterval = ((dateCreated  as NSString).integerValue / cut) * back
		date = Date(timeIntervalSince1970: Double(timeInterval))
		isLocal = file.isLocal ?? true
		isRemote = file.isRemote ?? true
		reUpload = file.reUpload ?? 0
		duration = file.duration
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
	var type:Int?
	var duration:UInt32 = 0
	
	var isLocal:Bool?
	var isRemote:Bool?
	var reUpload:Int?

	var date:Date?
	
	// Original File data
	var data:Data?

	class func mo() -> String {
		fatalError()
	}
	
	required init(file:FileMO) {
		dateCreated = file.dateCreated
		dateModified = file.dateModified
		name = file.name
		type = file.type
		headers = file.headers
		version = file.version ?? ""
		isLocal = file.isLocal
		isRemote = file.isRemote
		reUpload = file.reUpload
		date = file.date
		duration = file.duration
	}
	
	init(asset:PHAsset, path:URL) throws {
		let interval = Date.init().millisecondsSince1970
		dateCreated = "\(interval)"
		dateModified = dateCreated
		name = asset.value(forKey: "filename") as! String
		let cut = 24 * 3600 * 1000
		let back = 24 * 3600
		let timeInterval = (Int(interval) / cut) * back
		type = (asset.mediaType == .image) ? Constants.FileTypePhoto : Constants.FileTypeVideo
		headers = ""
		version = "\(Constants.CurrentFileVersion)"
		isLocal = true
		isRemote = false
		reUpload = 0
		date = Date(timeIntervalSince1970: Double(timeInterval))
		data = try Data(contentsOf: path)
		duration = UInt32(asset.duration)
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
