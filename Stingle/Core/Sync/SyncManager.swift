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
	
	static func dispatch(event:SPEvent) {
		guard let recievers:[SPEventHandler] = SyncManager.subscribers[event.name] else {
			return
		}
		for reciever in recievers {
			//TODO : make sure that the reciever can handle event
			reciever.recieve(event: event)
		}
	}
	
}
