import Foundation

protocol GalleryDelegate {
	func gallery(items:[String]);
}

class GalleryVM : SPEventHandler {
	
	private let db = DataBase()
	
	func recieve(event: SPEvent) {
		guard let info = event.info else {
			return
		}
		guard let files = info["fileName"] else {
			return
		}
		
		DispatchQueue.main.async {
			self.delegate?.gallery(items:files)
		}
	}
	
	
	var delegate:GalleryDelegate?
	init() {
		let event:SPEvent = SPEvent(name: SPEvenetType.DB.update.gallery.rawValue, info: nil)
		SyncManager.subscribe(to: event, reciever: self)
	}
}
