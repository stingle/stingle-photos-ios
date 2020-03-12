import Foundation
import UIKit

protocol GalleryDelegate {
	func update();
}

class GalleryVM : SPEventHandler {
	
	private var dataSource = [String: UIImage]()
	
	private let db = DataBase()
	
	private let crypto = Crypto()
	
	private var galleryFiles:Dictionary<Date, Array<SPFile>>?
		
	init() {
		let event:SPEvent = SPEvent(name: SPEvenetType.DB.update.gallery.rawValue, info: nil)
		SyncManager.subscribe(to: event, reciever: self)
		galleryFiles = files
	}
	
	private var files:Dictionary<Date, Array<SPFile>>?  { get {
		guard let files = db.filesFilteredByDate(), files.count > 0   else {
			return nil
		}
		return files
		}
	}
	
	public var sections:[Date]?  {
		get {
			galleryFiles?.keys.sorted().reversed()
		}
	}
	
	public func numberOfSections()  -> Int {
		guard let sections = sections else {
			return 0
		}
		return sections.count
	}
		
	public func numberOfrows(forSecion:Int) -> Int {
		
		guard let keys = sections else {
			return 0
		}
		
		let key = keys[forSecion]
		
		guard let filesInSection = galleryFiles?[key] else {
			return 0
		}
		return filesInSection.count
	}
	
	var delegate:GalleryDelegate?
	
	func recieve(event: SPEvent) {
		switch event.name {
		case SPEvenetType.DB.update.gallery.rawValue:
			galleryFiles = files
			DispatchQueue.main.async {
				self.delegate?.update()
			}
			break
		default:
			break
		}
	}
	
	func setupCell(cell:SPCollectionViewCell, forIndexPath:IndexPath) -> SPCollectionViewCell? {
		
		
		guard let keys = sections else {
			return nil
		}
		
		let key = keys[forIndexPath.section]
		
		guard let filesInSection = galleryFiles?[key] else {
			return nil
		}
		
		let file = filesInSection[forIndexPath.row].file
		
		if let image = dataSource[file] {
			cell.ImageView.image = image
			return cell
		}
		
		guard let filePath = SPFileManager.fullPathOfFile(fileName:file) else {
			return nil
		}
		
		guard let input = InputStream(url: filePath) else {
			return nil
		}
		input.open()
		
		let out = OutputStream.init(toMemory: ())
		out.open()
		
		do {
			_ = try crypto.decryptFile(input: input, output: out)
		} catch {
			print(error)
			return nil
		}
		
		let imageData = out.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data
		let newImage = UIImage(data:imageData)
		dataSource[file] = newImage
		cell.ImageView.image = newImage
		return cell
	}
	
}
