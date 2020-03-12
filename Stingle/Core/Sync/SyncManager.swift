import Foundation

class SyncManager {
		
	private static let db = DataBase()
	
	private static var subscribers = Dictionary<String, [SPEventHandler]>()
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contextWillSave(_:)), name: Notification.Name.NSManagedObjectContextWillSave, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: nil)
	}
	
	
	// MARK : Funcions for handle DB updates
	@objc func contextObjectsDidChange(_ notification: Notification) {
	}
	@objc func contextWillSave(_ notification: Notification) {
	}
	@objc func contextDidSave(_ notification: Notification) {
	}

	
	
	//TODO : check if subscriber is already subscibed
	static func subscribe<T:SPEventHandler>(to:SPEvent, reciever:T) {
		var value = subscribers[to.name]
		if value == nil {
			subscribers[to.name] = [reciever]
		} else {
			value?.append(reciever)
		}
	}
	
	private static func dispatch(event:SPEvent) {
		guard let recievers:[SPEventHandler] = SyncManager.subscribers[event.name] else {
			return
		}
		for reciever in recievers {
			//TODO : make sure that the reciever can handle event
			reciever.recieve(event: event)
		}
	}
	
	static func update() -> Bool {
		
		guard let info = db.getAppInfo() else {
			return false
		}
		
//		let request = SPGetUpdateRequest(token: SPApplication.user!.token, lastSeen: "\(info.lastSeen)", lastDelSeenTime: "\(info.lastDelSeen)")
		let request = SPGetUpdateRequest(token: SPApplication.user!.token, lastSeen: "\(0)", lastDelSeenTime: "\(info.lastDelSeen)")

		//		let request = SPGetUpdateRequest(token: SPApplication.user!.token, lastSeen: "0", lastDelSeenTime: "0")
		_ = NetworkManager.send(request: request) { (data:SPUpdateInfo?, error:Error?) in
			guard let data = data , error == nil else {
				print(error.debugDescription)
				return
			}
			let timeinterval = Date.init().millisecondsSince1970
			self.db.updateAppInfo(info: AppInfo(lastSeen: timeinterval, lastDelSeen: info.lastDelSeen))
			self.db.update(parts: data.parts)
			self.download(files: data.parts.files) { (fileName, error) in
				guard let fileName = fileName, error == nil else {
					print(error.debugDescription)
					return
				}
				SyncManager.dispatch(event: SPEvent(name: SPEvenetType.DB.update.gallery.rawValue, info:["fileName" : [fileName]]))
			}
			
			self.download(files: data.parts.trash) { (fileName, error) in
				guard let fileName = fileName, error == nil else {
					print(error.debugDescription)
					return
				}
				SyncManager.dispatch(event: SPEvent(name: SPEvenetType.DB.update.trash.rawValue, info:["fileName" : [fileName]]))
			}
		}
		return false
	}
	
	static func download (files:[SPFile], completionHandler:  @escaping (String?, Error?) -> Swift.Void) {
		for item in files {
			let req = SPDownloadFileRequest(token: SPApplication.user!.token, fileName: item.file, isThumb: true)
			_ = NetworkManager.download(request: req) { (url, error) in
				if error != nil {
					completionHandler(nil, error)
				} else {
					completionHandler(item.file, nil)
				}
			}
		}
	}
	
}
