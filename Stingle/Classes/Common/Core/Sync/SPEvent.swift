import Foundation

protocol SPEventHandler {
	func recieve(event:SPEvent);
}


class SPEvent {
	public let info:Dictionary<String, AnyHashable>?
	public let type:String
	
	init(type:String, info:Dictionary<String, AnyHashable>?) {
		self.type = type
		self.info = info
		
	}
}

extension SPEvent {
	enum Keys : String {
		case IndexPaths
		case Indexes
		case Sections
	}
	
	enum DB {
		
		enum update : String {
			case gallery = "SPDBUpdateGallery"
			case trash = "SPDBUpdateTrash"
			case appInfo = "SPDBUpdateAppInfo"
		}
		
		enum insert: String {
			case gallery = "SPDBInsertGallery"
			case trash = "SPDBInsertTrash"
		}
		
		enum delete: String {
			case gallery = "SPDBDeletetGallery"
			case trash = "SPDBDeletetTrash"
		}
	}
	
	enum UI {
		
		enum updates : String {
			case begin = "SPUIBeginUpdates"
			case end = "SPUIEndUpdates"
		}
		
		enum delete: String {
			case gallery = "SPUIDeletFromGallery"
		}
		
		enum recover: String {
			case trash = "SPUIRecoverFromTrash"
		}
		
		enum ready: String {
			case thumb = "SPUIThumbReady"
			case image = "SPUIImageReady"
			case video = "SPUIVideoReady"
		}
	}
}
