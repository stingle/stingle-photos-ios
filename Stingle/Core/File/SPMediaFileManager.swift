import Foundation
import UIKit
import Photos

class SPMediaFileManager {
	
	public static var manager = SPMediaFileManager()
	
	private let phManager = PHImageManager.default()
	
	private let sync = SPApplication.sync
	
	public func checkAndReqauestAuthorization(completion:@escaping (PHAuthorizationStatus) -> Void) {
		let status = PHPhotoLibrary.authorizationStatus()
		if status == .notDetermined  {
			PHPhotoLibrary.requestAuthorization({status in
				completion(status)
			})
		} else if status == .authorized {
			completion(status)
		}
	}
	
	func prepareMedia(info:[UIImagePickerController.InfoKey : Any]) {
		guard let asset:PHAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else {
			return
		}
		var mediaUrl:URL? = nil
		if asset.mediaType == .video {
			mediaUrl = info[UIImagePickerController.InfoKey.mediaURL] as! URL?
		} else if asset.mediaType == .image {
			mediaUrl = info[UIImagePickerController.InfoKey.imageURL] as! URL?
		} else {
			fatalError()
		}
		guard let fileUrl = mediaUrl else {
			return
		}
		processMediia(asset: asset, fileUrl: fileUrl)
	}
	
	func processMediia(asset:PHAsset, fileUrl:URL) {
		let option = PHImageRequestOptions()
		option.isSynchronous = true
		//TODO : Handle error case
		do {
			let file = try SPFile(asset: asset, path: fileUrl)
			let options = PHImageRequestOptions()
			options.version = .original
			options.isSynchronous = true
			options.deliveryMode = .highQualityFormat
			phManager.requestImageData(for: asset, options: options) { data, a, b, c in
				if let data = data {
					file.data = data
					SyncManager.importImage(file:file, withWidth: asset.pixelWidth, withHeight: asset.pixelHeight)
				}
			}
		} catch {
			print(error)
		}
	}
}
