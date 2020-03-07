import Foundation

protocol SPEventHandler {
	func recieve(event:SPEvent);
}

struct SPEvenetType {
	struct DB {
		enum update : String {
			case gallery
			case trash
			case appInfo
		}
	}
	
	struct FS {
		enum update: String {
			case newFileImported
		}
	}
}

class SPEvent {
	public let info:Dictionary<String, [String]>?
	public let name:String
	
	init(name:String, info:Dictionary<String, [String]>?) {
		self.name = name
		self.info = info
	}
}
