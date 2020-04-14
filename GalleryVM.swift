import Foundation
import UIKit

protocol GalleryDelegate {
	func update()
	
	func beginUpdates()
	func endUpdates()
	
	func updateItems(items:[IndexPath])
	func insertItems(items:[IndexPath])
	func insertSections(sections:IndexSet)
}

class GalleryVM : DataSourceDelegate, SPEventHandler {
	
	public var dataSource = DataSource(type: .Gallery)
	
	var delegate:GalleryDelegate?
	
	
	init() {
		let eventInfo:SPEvent = SPEvent(type: SPEvenetType.DB.update.appInfo.rawValue, info: nil)
		
		let eventGallery:SPEvent = SPEvent(type: SPEvenetType.DB.update.gallery.rawValue, info: nil)
		let eventTrash:SPEvent = SPEvent(type: SPEvenetType.DB.update.trash.rawValue, info: nil)
		
		let eventGalleryInsert:SPEvent = SPEvent(type: SPEvenetType.DB.insert.gallery.rawValue, info: nil)
		let eventTrashInsert:SPEvent = SPEvent(type: SPEvenetType.DB.insert.trash.rawValue, info: nil)

		let eventBegin:SPEvent = SPEvent(type: SPEvenetType.UI.updates.begin.rawValue, info: nil)
		let eventEnd:SPEvent = SPEvent(type: SPEvenetType.UI.updates.end.rawValue, info: nil)

		EventManager.subscribe(to: eventInfo, reciever: self)
		EventManager.subscribe(to: eventGallery, reciever: self)
		EventManager.subscribe(to: eventTrash, reciever: self)
		
		EventManager.subscribe(to: eventGalleryInsert, reciever: self)
		EventManager.subscribe(to: eventTrashInsert, reciever: self)

		EventManager.subscribe(to: eventBegin, reciever: self)
		EventManager.subscribe(to: eventEnd, reciever: self)

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
		let screenSize: CGRect = UIScreen.main.bounds
		let width = screenSize.size.width / 3
		let height = width
//		if let image = dataSource.thumb(forIndexPath: indexPath)?.resize(size: CGSize(width: width, height: height)) {
		if let image = dataSource.thumb(indexPath: indexPath) {
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
	
	func originalImageReady(at index:Int) {
		
	}
	
	func beginUpdates() {
		self.delegate?.beginUpdates()

	}
	
	func endUpdates() {
		self.delegate?.endUpdates()
	}

	func recieve(event: SPEvent) {
		switch event.type {
		case SPEvenetType.DB.update.gallery.rawValue, SPEvenetType.DB.update.trash.rawValue:
			guard let info = event.info  else {
				return
			}
			guard let files = info["fileName"] as! [String]? else {
				return
			}
			guard let fileName = files.first else {
				return
			}
			guard let index = dataSource.indexPath(for: fileName) else {
				return
			}
			self.delegate?.updateItems(items: [index])
			break
		case SPEvenetType.DB.insert.gallery.rawValue, SPEvenetType.DB.insert.trash.rawValue:
			guard let info = event.info  else {
				return
			}
			if let indexPaths = info["idexPaths"] as! [IndexPath]? {
				self.delegate?.insertItems(items: indexPaths)
			} else if let sections = info["sections"] as! IndexSet? {
				self.delegate?.insertSections(sections: sections)
			}
			break
		case SPEvenetType.DB.update.appInfo.rawValue:
			self.delegate?.update()
			break
		case SPEvenetType.UI.updates.begin.rawValue:
			beginUpdates()
			break
		case SPEvenetType.UI.updates.end.rawValue:
			endUpdates()
			break
		default:
			break
		}
	}
}

extension GalleryVM : SPMenuDelegate {
	func selectedMenuItem(with index: Int) {
		switch index {
		case 0:
			if dataSource.type != .Gallery {dataSource.type = .Gallery}
			self.delegate?.update()
		case 1:
			if dataSource.type != .Trash {dataSource.type = .Trash}
			self.delegate?.update()
		case 2, 3, 4, 5:
			return
		default:
			return
		}
	}
}

