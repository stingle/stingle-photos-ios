import Foundation
class EventManager {
	private static var subscribers = Dictionary<String, [SPEventHandler]>()
	
	//TODO : check if subscriber is already subscibed
	static func subscribe<T:SPEventHandler>(to:SPEvent, reciever:T) {
		var value = subscribers[to.type]
		if value == nil {
			subscribers[to.type] = [reciever]
		} else {
			value?.append(reciever)
		}
	}
	
	static func dispatch(event:SPEvent) {
		guard let recievers:[SPEventHandler] = EventManager.subscribers[event.type] else {
			return
		}
		for reciever in recievers {
			//TODO : make sure that the reciever can handle event
			reciever.recieve(event: event)
		}
	}
}
