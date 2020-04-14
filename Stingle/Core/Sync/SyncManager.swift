import Foundation
import UIKit
import CoreData
class SyncManager {

	public static let db = DataBase.shared
	private static let fileManger = SPFileManager()
	private static let crypto = Crypto()
	
	
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
			processFiles(files: data.parts.files)
			processFiles(files: data.parts.trash)
			completionHandler(true)
			EventManager.dispatch(event: SPEvent(type: SPEvenetType.DB.update.appInfo.rawValue, info:nil))
		}
		return
	}
	
	static func processFiles<T:SPFileInfo>(files:[T]) {
		var folder = NSNotFound
		var type = SPEvenetType.DB.update.gallery.rawValue
		if T.self is SPFile.Type {
				folder = 0
		} else if T.self is SPTrashFile.Type {
			folder = 1
			type = SPEvenetType.DB.update.trash.rawValue
		}
		for file in files {
			var needUpdate = false
			var needDownload = false
			if let oldFile:T = db.isFileExist(name: file.name) {
				if (oldFile.dateModified as NSString).integerValue < (file.dateModified as NSString).integerValue {
					needUpdate = true
				}
				if let isRemote = file.isRemote, !isRemote {
					needUpdate = true
				}
				if file.version > oldFile.version {
					needUpdate = true
					needDownload = true
				}
			} else {
				db.add(files: [file])
				self.downloadThumbs(files: [file], folder: folder) { (fileName, error) in
					EventManager.dispatch(event: SPEvent(type: type, info:["fileName" : [file.name]]))
				}
			}
			if needUpdate {
				_ = db.updateFile(file: file)
				EventManager.dispatch(event:	 SPEvent(type: type, info:["fileName" : [file.name]]))
			}
			if needDownload {
				self.downloadThumbs(files: [file], folder: folder) { (fileName, error) in
					guard let fileName = fileName, error == nil else {
						print(error.debugDescription)
						return
					}
					EventManager.dispatch(event: SPEvent(type: type, info:["fileName" : [fileName]]))
				}
				self.downloadFiles(files: [file], folder: folder) { (fileName, error) in
				}
			}
		}
	}
	
	static func downloadFiles <T:SPFileInfo>(files:[T], folder:Int, completionHandler:  @escaping (String?, Error?) -> Swift.Void) {
		download(files: files, isThumb: false, folder: folder, completionHandler: completionHandler)
	}

	static func downloadThumbs <T:SPFileInfo>(files:[T], folder:Int, completionHandler:  @escaping (String?, Error?) -> Swift.Void) {
		download(files: files, isThumb: true, folder: folder, completionHandler: completionHandler)
	}

	static func download <T:SPFileInfo>(files:[T], isThumb: Bool, folder:Int, completionHandler:  @escaping (String?, Error?) -> Swift.Void) {
		for item in files {
			let request = SPDownloadFileRequest(token: SPApplication.user!.token, fileName: item.name, isThumb: isThumb, folder:folder)
			_ = NetworkManager.download(request: request) { (url, error) in
				if error != nil {
					completionHandler(nil, error)
				} else {
					completionHandler(item.name, nil)
				}
			}
		}
	}

	
	static func importImage(file:SPFile, withWidth:Int, withHeight:Int) {
		guard let fileName = Utils.getNewEncFilename() else {
			return
		}
		
		guard let fileId = crypto.newFileId() else {
			return
		}
		guard let data = file.data else {
			return
		}
		let size = UIConstants.thumbSize(for: CGSize(width: withWidth, height: withHeight))
		let image = UIImage(data: data)
		let thumbImage = image?.scale(to: size.width)
		
		guard let thumbData = thumbImage?.pngData() as Data? else {
			return
		}
		let inputThumb = InputStream(data: thumbData)
		inputThumb.open()
		guard let thumbPath = SPFileManager.folder(for: .StorageThumbs)?.appendingPathComponent(fileName) else {
			return
		}
		guard let outputThumb = OutputStream(toFileAtPath: thumbPath.path, append: false) else {
			return
		}
		outputThumb.open()
		let inputOrigin = InputStream(data: data)
		inputOrigin.open()
		guard let originalPath = SPFileManager.folder(for: .StorageOriginals)?.appendingPathComponent(fileName) else {
			return
		}
		guard let outputOrigin = OutputStream(toFileAtPath: originalPath.path, append: false) else {
			return
		}
		outputOrigin.open()
		do {
			guard let type = file.type else {
				throw CryptoError.General.incorrectParameterSize
			}
			try crypto.encryptFile(input: inputThumb, output: outputThumb, filename: file.name, fileType: type, dataLength: UInt(thumbData.count), fileId: fileId, videoDuration: file.duration)
			inputThumb.close()
			outputThumb.close()
			try crypto.encryptFile(input: inputOrigin, output: outputOrigin, filename: file.name, fileType: type, dataLength: UInt(data.count), fileId: fileId, videoDuration: file.duration)
			inputOrigin.close()
			outputOrigin.close()
			guard let headers = try SPApplication.crypto.getFileHeaders(originalPath: originalPath.path, thumbPath: thumbPath.path) else {
				//TODO : throw right exception
				throw CryptoError.General.incorrectParameterSize
			}
			file.headers = headers
			file.name = fileName
			db.add(files: [file])
			NetworkManager.upload(file: file, folder: 0) { (space, quota, error) in
				if nil == error {
					db.marFileAsRemote(file: file)
				}
			}
		} catch {
			print(error)
		}
	}
	
	deinit {
	}
	
}
