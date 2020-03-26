
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
	private let type:SourceType
	private static let db = DataBase()
	private static let crypto = Crypto()
	private static let network = NetworkManager()
	private static let sync = SyncManager()
	
	//TODO : Replace with round buffer
	private var memoryCache:[String: UIImage]
	
	var delegate:DataSourceDelegate?
	
	init(type:SourceType) {
		self.type = type
		memoryCache = [String: UIImage]()
	}
	
	static func update(completionHandler:  @escaping (Bool) -> Swift.Void) {
		
		guard let info = db.getAppInfo() else {
			return
		}
		
		let request = SPGetUpdateRequest(token: SPApplication.user!.token, lastSeen: "\(info.lastSeen)", lastDelSeenTime: "\(info.lastDelSeen)")
		
		//		let request = SPGetUpdateRequest(token: SPApplication.user!.token, lastSeen: "0", lastDelSeenTime: "0")
		_ = NetworkManager.send(request: request) { (data:SPUpdateInfo?, error:Error?) in
			guard let data = data , error == nil else {
				print(error.debugDescription)
				completionHandler(false)
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
			completionHandler(true)
		}
		return
	}
	
	static func download <T:SPFileInfo>(files:[T], completionHandler:  @escaping (String?, Error?) -> Swift.Void) {
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
	
	private var files:[SPFile]?  { get {
		guard let files:[SPFile] = DataSource.db.filesSortedByDate()  else {
			return nil
		}
		return files
		}
	}
	
	private var trash:[SPTrashFile]?  { get {
		guard let files:[SPTrashFile] = DataSource.db.filesSortedByDate(), files.count > 0   else {
			return nil
		}
		return files
		}
	}
	
	public func numberOfSections()  -> Int {
		switch type {
		case .Gallery:
			return DataSource.db.numberOfSections(for: SPFile.self)
		case .Trash:
			return DataSource.db.numberOfSections(for: SPTrashFile.self)
		default:
			return 0
		}
	}
	
	public func numberOfRows(forSecion:Int) -> Int {
		switch type {
		case .Gallery:
			return DataSource.db.numberOfRows(for: forSecion, with: SPFile.self)
		case .Trash:
			return DataSource.db.numberOfRows(for: forSecion, with: SPTrashFile.self)
		default:
			return 0
		}
	}
	
	public func sectionTitle(for secion:Int) -> String? {
		switch type {
		case .Gallery:
			return DataSource.db.sectionTitle(for: secion, with: SPFile.self)
		case .Trash:
			return DataSource.db.sectionTitle(for: secion, with: SPTrashFile.self)
		default:
			return nil
		}
	}
	
	func image(for indexPath:IndexPath) -> UIImage? {
		guard let file:SPFile = DataSource.db.fileForIndexPath(indexPath: indexPath) else {
			return nil
		}
		
		if let image = memoryCache[file.file] {
			return image
		}
		
		guard let filePath = SPFileManager.fullPathOfFile(fileName:file.file) else {
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
					return
				}
				let imageData = out.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data
				let screenSize: CGRect = UIScreen.main.bounds
				let width = screenSize.size.width / 3
				let height = width
				DispatchQueue.main.async {
					let newImage = UIImage(data:imageData)?.resize(size: CGSize(width: width, height: height))
					self.memoryCache[file.file] = newImage
					self.delegate?.imageReady(at: indexPath)
				}
			}
			body()
		})
		return nil
	}

	func file(for indexPath:IndexPath) -> SPFile? {
		return DataSource.db.fileForIndexPath(indexPath: indexPath)
	}
	
	func indexPath(for file:String) -> IndexPath? {
		return DataSource.db.indexPath(for: file, with: SPFile.self)
	}
	
}
