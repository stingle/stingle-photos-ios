import Foundation
import UIKit
class SyncManager {
	
	private static let db = DataBase()
	private static let fileManger = SPFileManager()
	private static let crypto = Crypto()
		
	private static var subscribers = Dictionary<String, [SPEventHandler]>()
	
	init() {
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
	static func encryptAndSave(file:SPFile, folder:SPFolder) {
		
	}
	
	static func importImage(file:SPFile, withWidth:Int, withHeight:Int) {

		guard let fileId = crypto.newFileId() else {
			return
		}

		guard let data = file.data else {
			return
		}
		
		let size = UIConstants.thumbSize(for: CGSize(width: withWidth, height: withHeight))
		guard let thumbData = UIImage(data: data)?.resize(size: size)?.pngData() else {
			return
		}

		let inputThumb = InputStream(data: thumbData)
		inputThumb.open()

		guard let thumbPath = SPFileManager.folder(for: .StorageThumbs)?.appendingPathComponent(file.name) else {
			return
		}
		
		guard let outputThumb = OutputStream(toFileAtPath: thumbPath.path, append: false) else {
			return
		}
		outputThumb.open()

		let inputOrigin = InputStream(data: data)
		inputOrigin.open()
				
		guard let originalPath = SPFileManager.folder(for: .StorageOriginals)?.appendingPathComponent(file.name) else {
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
			try crypto.encryptFile(input: inputThumb, output: outputThumb, filename: file.name, fileType: type, dataLength: UInt(data.count), fileId: fileId, videoDuration: file.duration)
			try crypto.encryptFile(input: inputOrigin, output: outputOrigin, filename: file.name, fileType: type, dataLength: UInt(data.count), fileId: fileId, videoDuration: file.duration)
			guard let headers = try SPApplication.crypto.getFileHeaders(originalPath: originalPath.path, thumbPath: thumbPath.path) else {
				//TODO : throw right exception
				throw CryptoError.General.incorrectParameterSize
			}
			file.headers = headers
			db.add(spfile: file)
		} catch {
			print(error)
		}
	}
	
	deinit {
	}
	
}
