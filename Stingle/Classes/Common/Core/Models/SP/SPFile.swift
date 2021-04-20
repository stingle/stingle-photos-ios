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

class CredsMO : NSManagedObject {
	@NSManaged var token:String
	@NSManaged var isSignedIn:Bool
		
	func update(isSignedIn:Bool, token:String) {
		self.isSignedIn = isSignedIn
		self.token = token
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
	
	// Original File data
	var data:Data?

	class func mo() -> String {
		fatalError()
	}
	
	required init(file:FileMO) {
		dateCreated = file.dateCreated
		dateModified = file.dateModified
		name = file.name
		headers = file.headers
		version = file.version ?? ""
		isLocal = file.isLocal
		isRemote = file.isRemote
		reUpload = file.reUpload
		date = file.date
	}
	
	init(asset:PHAsset, path:URL) throws {
		let interval = Date.init().millisecondsSince1970
		dateCreated = "\(interval)"
		dateModified = dateCreated
		name = asset.value(forKey: "filename") as! String
		let cut = 24 * 3600 * 1000
		let back = 24 * 3600
		let timeInterval = (Int(interval) / cut) * back
		headers = ""
        version = "\(STCrypto.Constants.CurrentFileVersion)"
		isLocal = true
		isRemote = false
		reUpload = 0
		date = Date(timeIntervalSince1970: Double(timeInterval))
		data = try Data(contentsOf: path)
	}

	func duration() -> UInt32 {
		let headers = self.headers
		let hdrs = headers.split(separator: "*")
        let crypto = STApplication.shared.crypto
		for hdr in hdrs {
            let st = STApplication.shared.crypto.base64urlToBase64(base64urlString:String(hdr))
            if let data = STApplication.shared.crypto.base64ToByte(encodedStr: st) {
				let input = InputStream(data: Data(data))
				input.open()
				do {
					let header = try crypto.getFileHeader(input: input)
					input.close()
					return header.videoDuration
				} catch {
					print(error)
				}
				input.close()
			}
		}
		return 0
	}
	
	func getOriginalHeader () -> STHeader? {
		let headers = self.headers
		let hdrs = headers.split(separator: "*")
		let hdr = hdrs[0]
        let crypto = STApplication.shared.crypto
		let st = crypto.base64urlToBase64(base64urlString: String(hdr))
		if let data = crypto.base64ToByte(encodedStr: st) {
			let input = InputStream(data: Data(data))
			input.open()
			do {
				let header = try crypto.getFileHeader(input: input)
				input.close()
				return header
			} catch {
				print(error)
			}
			input.close()
		}
		return nil
	}
	
	func type() -> Int {
		let headers = self.headers
		let hdrs = headers.split(separator: "*")
        let crypto = STApplication.shared.crypto
		for hdr in hdrs {
            let st = crypto.base64urlToBase64(base64urlString: String(hdr))
			if let data = crypto.base64ToByte(encodedStr: st) {
				let input = InputStream(data: Data(data))
				input.open()
				do {
					let header = try crypto.getFileHeader(input: input)
					input.close()
					return Int(header.fileType)
				} catch {
					print(error)
				}
				input.close()
			}
		}
		return -1
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
