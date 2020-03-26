import Foundation
import UIKit

protocol GalleryDelegate {
	func update()
	func updateItems(items:[IndexPath])
}

class GalleryVM : DataSourceDelegate, SPEventHandler {
	
	public var dataSource = DataSource(type: .Gallery)
	
	var delegate:GalleryDelegate?
	
	init() {
		let event:SPEvent = SPEvent(name: SPEvenetType.DB.update.gallery.rawValue, info: nil)
		let eventTrash:SPEvent = SPEvent(name: SPEvenetType.DB.update.trash.rawValue, info: nil)
		SyncManager.subscribe(to: event, reciever: self)
		SyncManager.subscribe(to: eventTrash, reciever: self)
		dataSource.delegate = self
	}
	
	func numberOfSections() -> Int {
		return dataSource.numberOfSections()
	}
	
	func numberOfRows(forSecion: Int) -> Int {
		return dataSource.numberOfRows(forSecion: forSecion)
	}
	
	func sectionTitle(forSection:Int) -> String? {
		guard let title = dataSource.sectionTitle(for: forSection) else {
			return nil
		}
		let olDateFormatter = DateFormatter()
		olDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
		guard let oldDate = olDateFormatter.date(from: title) else {
			return nil
		}
		let convertDateFormatter = DateFormatter()
		convertDateFormatter.dateFormat = "MMMM d, yyyy"
		return convertDateFormatter.string(from: oldDate)
	}
	
	func setupCell(cell:SPCollectionViewCell, for indexPath:IndexPath) {
		if let image = dataSource.image(for: indexPath) {
			DispatchQueue.main.async {
				cell.ImageView.image = image
			}
			return
		}
	}
}


//MARK: - DataSource Delagate
extension GalleryVM {
	func imageReady(at indexPath: IndexPath) {
		self.delegate?.updateItems(items: [indexPath])
	}
	
	func recieve(event: SPEvent) {
		switch event.name {
		case SPEvenetType.DB.update.gallery.rawValue:
			
			if let info = event.info {
				guard let fileName = info["fileName"]?.first else {
					return
				}
				guard let index = dataSource.indexPath(for: fileName) else {
					return
				}
				self.delegate?.updateItems(items: [index])
			} else {
				self.delegate?.update()
			}
			
			break
		default:
			break
		}
	}
	
}
