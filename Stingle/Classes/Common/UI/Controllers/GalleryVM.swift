import Foundation
import UIKit

protocol GalleryDelegate {
	
	func signOut()
	func update()
	func endEditing()
	func setSet(set:GalleryVC.Set)
	
	func beginUpdates()
	func endUpdates()
	
	func updateItems(items:[IndexPath])
	func insertItems(items:[IndexPath])
	func insertSections(sections:IndexSet)
	
	func deleteItems(items:[IndexPath])
	func deleteSections(sections: IndexSet)

}

class GalleryVM : DataSourceDelegate, SPEventHandler {
	
	private var selectedItems = [IndexPath: SPFileInfo]()
	
	public var dataSource = DataSource(type: .Gallery)
	
	var delegate:GalleryDelegate?
	
	
	init() {
		let eventInfo:SPEvent = SPEvent(type: SPEvent.DB.update.appInfo.rawValue, info: nil)
		
		let eventGallery:SPEvent = SPEvent(type: SPEvent.DB.update.gallery.rawValue, info: nil)
		let eventTrash:SPEvent = SPEvent(type: SPEvent.DB.update.trash.rawValue, info: nil)
		
		let eventGalleryInsert:SPEvent = SPEvent(type: SPEvent.DB.insert.gallery.rawValue, info: nil)
		let eventTrashInsert:SPEvent = SPEvent(type: SPEvent.DB.insert.trash.rawValue, info: nil)

		let eventBegin:SPEvent = SPEvent(type: SPEvent.UI.updates.begin.rawValue, info: nil)
		let eventEnd:SPEvent = SPEvent(type: SPEvent.UI.updates.end.rawValue, info: nil)

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
	
	func cancelEditing() {
		selectedItems.removeAll()
	}

	func trashSelected() {
		let files:[SPFileInfo] = [SPFileInfo](selectedItems.values)
		moveFiles(files: files, from: .Gallery, to: .Trash)
	}
	
	func deleteSelected() {
		let files:[SPFileInfo] = [SPFileInfo](selectedItems.values)
		moveFiles(files: files, from: .Trash, to: .Null)
	}
	
	func restoreSelected() {
		let files:[SPFileInfo] = [SPFileInfo](selectedItems.values)
		moveFiles(files: files, from: .Trash, to: .Gallery)
	}

	func emptyTrash() {
		let files:[SPFileInfo] = [SPFileInfo](selectedItems.values)
		moveFiles(files: files, from: .Trash, to: .Empty)
	}
	
	func moveFiles(files:[SPFileInfo], from:SPSet, to:SPSet) {
		_ = SyncManager.moveFiles(files: files, from: from, to: to) { error in
			if error == nil {
				self.delegate?.endEditing()
			}
		}
	}

	
	func select(item cell:SPCollectionViewCell, at indexPath:IndexPath) {
		if selectedItems[indexPath] != nil {
			selectedItems.removeValue(forKey: indexPath)
		} else {
			if dataSource.fileType() == SPTrashFile.self {
				guard let file:SPTrashFile = dataSource.trashFile(for: indexPath) else {
					return
				}
				selectedItems[indexPath] = file
			} else {
				guard let file:SPFile = dataSource.file(for: indexPath) else {
					return
				}
				selectedItems[indexPath] = file
			}
		}
	}
	
	func setupCell(cell:SPCollectionViewCell, for indexPath:IndexPath, mode:GalleryVC.Mode, with size:CGSize?) {
		guard let size = size else {
			return
		}
		if let image = dataSource.thumb(indexPath: indexPath)?.resize(size: size) {
			DispatchQueue.main.async {
				cell.ImageView.image = image
			}
		}
		
		if mode == .Editing {
			cell.selectIcon.isHidden = false
			cell.updateSpaces(constant: 14)
			if selectedItems[indexPath] == nil {
				cell.selectIcon.tintColor = .lightGray
				cell.selectIcon.image = UIImage(named: "rectangle")
			} else {
				cell.selectIcon.image = UIImage(named: "checkmark.rectangle.fill")
				cell.selectIcon.tintColor = Theme.Colors.SPRed
			}
		} else {
			cell.updateSpaces(constant: 0)
			cell.selectIcon.isHidden = true
		}
		
		guard let file = dataSource.fileInfo(for: indexPath) else {
			return
		}
		if file.duration() > 0 {
			cell.duration.isHidden = false
			cell.videoIcon.isHidden = false
			let duration = file.duration()
			let minutes = duration / 60
			let seconds = duration - minutes * 60
			let secondsText = seconds < 10 ? "0\(seconds)" : "\(seconds)"
			let text = "\(minutes):\(secondsText)"
			cell.duration.text = text
		} else {
			cell.duration.isHidden = true
			cell.videoIcon.isHidden = true
		}
		
		if let isRemote = file.isRemote {
			cell.notSyncedIcon.isHidden = (isRemote && (mode != .Editing))
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
		print(event.type)
		switch event.type {
		case SPEvent.DB.update.gallery.rawValue:
			if dataSource.type != .Gallery { return }
			guard let info = event.info  else {
				return
			}
			guard let indexPaths = info[SPEvent.Keys.IndexPaths.rawValue] as! [IndexPath]? else {
				return
			}
			self.delegate?.updateItems(items: indexPaths)
			break
		case SPEvent.DB.update.trash.rawValue:
			if dataSource.type != .Trash { return }
			guard let info = event.info  else {
				return
			}
			guard let indexPaths = info[SPEvent.Keys.IndexPaths.rawValue] as! [IndexPath]? else {
				return
			}
			self.delegate?.updateItems(items: indexPaths)
			break
		case SPEvent.DB.insert.gallery.rawValue:
			if dataSource.type != .Gallery { return}
			guard let info = event.info  else {
				return
			}
			if let indexPaths = info[SPEvent.Keys.IndexPaths.rawValue]{
				self.delegate?.insertItems(items: indexPaths  as! [IndexPath] )
			} else if let sections = info[SPEvent.Keys.Sections.rawValue]{
				self.delegate?.insertSections(sections: sections  as! IndexSet)
			}
			break
		case SPEvent.DB.insert.trash.rawValue:
			if dataSource.type != .Trash { return}
			guard let info = event.info  else {
				return
			}
			if let indexPaths = info[SPEvent.Keys.IndexPaths.rawValue]{
				self.delegate?.insertItems(items: indexPaths  as! [IndexPath] )
			} else if let sections = info[SPEvent.Keys.Sections.rawValue]{
				self.delegate?.insertSections(sections: sections  as! IndexSet)
			}
			break

		case SPEvent.DB.delete.gallery.rawValue:
			if dataSource.type != .Gallery { return}
			guard let info = event.info  else {
				return
			}
			if let indexPaths = info[SPEvent.Keys.IndexPaths.rawValue]{
				self.delegate?.deleteItems(items: indexPaths  as! [IndexPath] )
			} else if let sections = info[SPEvent.Keys.Sections.rawValue]{
				self.delegate?.deleteSections(sections: sections  as! IndexSet)
			}
			break
		case SPEvent.DB.delete.trash.rawValue:
			if dataSource.type != .Trash { return}
			guard let info = event.info  else {
				return
			}
			if let indexPaths = info[SPEvent.Keys.IndexPaths.rawValue]{
				self.delegate?.deleteItems(items: indexPaths  as! [IndexPath] )
			} else if let sections = info[SPEvent.Keys.Sections.rawValue]{
				self.delegate?.deleteSections(sections: sections  as! IndexSet)
			}
			break
		case SPEvent.DB.update.appInfo.rawValue:
//			self.delegate?.updateData()
			break
		case SPEvent.UI.updates.begin.rawValue:
			beginUpdates()
			break
		case SPEvent.UI.updates.end.rawValue:
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
			self.delegate?.setSet(set: .Gallery)
			self.delegate?.update()
		case 1:
			if dataSource.type != .Trash {dataSource.type = .Trash}
			self.delegate?.setSet(set: .Trash)
			self.delegate?.update()
		case 2, 3, 4:
			return
		case 5:
			_ = SyncManager.signOut { (status, error) in
				KeyManagement.signOut()
				self.delegate?.signOut()
			}
			return

		default:
			return
		}
	}
}

