import Foundation
import UIKit
import Photos

class SPMediaFileManager {
	
	public static var manager = SPMediaFileManager()
	
	private let phManager = PHImageManager.default()
	
//	private let sync = STApplication.shared.sync
	
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
		var type = Constants.FileTypeGeneral
		var duration:UInt32 = 0
		var mediaUrl:URL? = nil
		if asset.mediaType == .video {
			type = Constants.FileTypeVideo
			duration = UInt32(asset.duration)
			mediaUrl = info[UIImagePickerController.InfoKey.mediaURL] as! URL?
		} else if asset.mediaType == .image {
			type = Constants.FileTypePhoto
			mediaUrl = info[UIImagePickerController.InfoKey.imageURL] as! URL?
		} else {
			fatalError()
		}
		guard let fileUrl = mediaUrl else {
			return
		}
		processMediia(asset: asset, fileUrl: fileUrl, type:type, duration:duration)
	}
	
	func processMediia(asset:PHAsset, fileUrl:URL, type:Int, duration:UInt32) {
		let option = PHImageRequestOptions()
		option.isSynchronous = true
		//TODO : Handle error case
		do {
			let file = try SPFile(asset: asset, path: fileUrl)
			let options = PHImageRequestOptions()
			options.version = .original
			options.isSynchronous = false
			options.deliveryMode = .highQualityFormat
			options.isNetworkAccessAllowed = true
			let size = STConstants.thumbSize(for: CGSize(width: asset.pixelWidth, height: asset.pixelHeight))

			phManager.requestImage(for: asset, targetSize:size, contentMode: .aspectFit, options: options) { thumb,info  in
				if let thumb = thumb {
					SyncManager.importImage(file:file, thumb:thumb, type:type, duration:duration)
				}
			}

		} catch {
			print(error)
		}
	}
}
