
import Foundation
import UIKit

enum SourceType {
	case Gallery
	case Trash
	case Album
	case SharedAlbums
}

protocol DataSourceDelegate {
	func imageReady(at indexPath:IndexPath)
}

class DataSource {
	public var type:SourceType
	static let db = DataBase()
	private static let crypto = Crypto()
	private static let network = NetworkManager()
	
	//TODO : Replace with round buffer
	private var thumbCache:[String: UIImage]
	private var imageCache:[String: UIImage]
	
	var delegate:DataSourceDelegate?
	
	init(type:SourceType) {
		self.type = type
		thumbCache = [String: UIImage]()
		imageCache = [String: UIImage]()
	}
	
	static func update(completionHandler:  @escaping (Bool) -> Swift.Void) {
		guard let info = db.getAppInfo() else {
			return
		}
		let request = SPGetUpdateRequest(token: SPApplication.user!.token, lastSeen: "\(info.lastSeen)", lastDelSeenTime: "\(info.lastDelSeen)")
		_ = NetworkManager.send(request: request) { (data:SPUpdateInfo?, error:Error?) in
			guard let data = data , error == nil else {
				print(error.debugDescription)
				completionHandler(false)
				return
			}
			let timeinterval = Date.init().millisecondsSince1970
			self.db.updateAppInfo(info: AppInfo(lastSeen: timeinterval, lastDelSeen: info.lastDelSeen, spaceQuota: data.parts.spaceQuota, spaceUsed: data.parts.spaceUsed))
			self.db.update(parts: data.parts)
			self.download(files: data.parts.files) { (fileName, error) in
				guard let fileName = fileName, error == nil else {
					print(error.debugDescription)
					return
				}
				SyncManager.dispatch(event:	 SPEvent(name: SPEvenetType.DB.update.gallery.rawValue, info:["fileName" : [fileName]]))
			}
			self.download(files: data.parts.trash) { (fileName, error) in
				guard let fileName = fileName, error == nil else {
					print(error.debugDescription)
					return
				}
				SyncManager.dispatch(event: SPEvent(name: SPEvenetType.DB.update.trash.rawValue, info:["fileName" : [fileName]]))
			}
			completionHandler(true)
		}
		return
	}
	
	static func download <T:SPFileInfo>(files:[T], completionHandler:  @escaping (String?, Error?) -> Swift.Void) {
		var folder = NSNotFound
		if T.self is SPFile.Type {
				folder = 0
		} else if T.self is SPTrashFile.Type {
			folder = 1
		}
		for item in files {
			let req = SPDownloadFileRequest(token: SPApplication.user!.token, fileName: item.name, isThumb: true, folder:folder)
			_ = NetworkManager.download(request: req) { (url, error) in
				if error != nil {
					completionHandler(nil, error)
				} else {
					completionHandler(item.name, nil)
				}
			}
		}
	}
	
	private var files:[SPFile]?  { get {
		guard let files:[SPFile] = DataSource.db.filesSortedByDate()  else {
			return nil
		}
		return files
		}
	}
	
	private var trash:[SPTrashFile]?  { get {
		guard let files:[SPTrashFile] = DataSource.db.filesSortedByDate() else {
			return nil
		}
		return files
		}
	}
	
//	MARK: - IndexPath getters
	
	public func numberOfSections()  -> Int {
		return DataSource.db.numberOfSections(for: fileType())
	}
	
	public func numberOfRows(forSecion:Int) -> Int {
		return DataSource.db.numberOfRows(for: forSecion, with: fileType())
	}
	
	public func sectionTitle(for secion:Int) -> String? {
		return DataSource.db.sectionTitle(for: secion, with: fileType())
	}
	
	func file(for indexPath:IndexPath) -> SPFileInfo? {
		return DataSource.db.fileForIndexPath(indexPath: indexPath, with: fileType())
	}
	
	func indexPath(for file:String) -> IndexPath? {
		return DataSource.db.indexPath(for: file, with: fileType())
	}
	
	func image(for indexPath:IndexPath) -> UIImage? {
		guard let file:SPFileInfo = DataSource.db.fileForIndexPath(indexPath: indexPath, with: fileType()) else {
			return nil
		}
		
		if let image = imageCache[file.name] {
			return image
		}
		guard let filePath = SPFileManager.folder(for: .StorageThumbs)?.appendingPathComponent(file.name) else {
			return nil
		}
		
		guard let input = InputStream(url: filePath) else {
			return nil
		}
		input.open()
		
		let out = OutputStream.init(toMemory: ())
		out.open()
		
		DataSource.crypto.decryptFileAsync(input: input, output: out, completion: { (ok, error) in
			let body = {() -> Void in
				guard ok == true, error == nil else {
					print(error)
					return
				}
				let imageData = out.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data
				DispatchQueue.main.async {
					self.imageCache[file.name] = UIImage(data:imageData)
					self.delegate?.imageReady(at: indexPath)
				}
			}
			body()
		})
		return nil
	}

//	MARK: - Index getters
	func numberOfFiles () -> Int {
		return DataSource.db.filesCount(for: fileType())
	}
	
	func thumb(for index:Int) -> UIImage? {
		guard let file:SPFileInfo = DataSource.db.fileForIndex(index: index, for: fileType()) else {
			return nil
		}
		guard let image = thumbCache[file.name] else {
			return nil
		}
		return image
	}
	
	func image(for index:Int) -> UIImage? {
		guard let file:SPFileInfo = DataSource.db.fileForIndex(index: index, for: fileType()) else {
			return nil
		}
		guard let image = imageCache[file.name] else {
			return nil
		}
		return image
	}

	func index(of file:SPFileInfo) -> Int {
		return 0
	}
	
	func index(for indexPath:IndexPath) -> Int {
		return DataSource.db.index(for: indexPath, of: fileType())
	}
	
//	MARK: - Helpers
	func fileType() -> SPFileInfo.Type {
		switch type {
		case .Gallery:
			return  SPFile.self
		case .Trash:
			return  SPTrashFile.self
		default:
			return SPFileInfo.self
		}
	}
	
}
