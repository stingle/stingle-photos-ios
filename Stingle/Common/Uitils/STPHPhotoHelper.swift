//
//  STImagePickerHelper.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import UIKit
import Photos
import PhotosUI

protocol STImagePickerHelperDelegate: UIViewController {
    func pickerViewController(_ imagePickerHelper: STPHPhotoHelper, didPickAssets assets: [PHAsset], failedAssetCount: Int)
    func pickerViewControllerDidCancel(_ imagePickerHelper: STPHPhotoHelper)
}

extension STImagePickerHelperDelegate {
    func pickerViewControllerDidCancel(_ imagePickerHelper: STPHPhotoHelper) {}
    func pickerViewController(_ imagePickerHelper: STPHPhotoHelper, didPickAssets assets: [PHAsset]) {}
}

class STPHPhotoHelper: NSObject {
        
    weak var viewController: STImagePickerHelperDelegate?
    
    init(controller: STImagePickerHelperDelegate?) {
        self.viewController = controller
    }
    
    func openPicker() {
        Self.checkAndReqauestAuthorization { (status) in
            switch status {
            case .authorized, .limited:
                self.open()
                break
            default:
                self.showAuthorizationPermissionAlert()
                break
            }
        }
    }
    
    func deleteAssetsAfterManualImport(assets: [PHAsset]) {
        let deleteFilesType = STAppSettings.current.import.manualImportDeleteFilesType
        switch deleteFilesType {
        case .never:
            break
        case .askEveryTime:
            let title = "delete_original_files".localized
            let message = "alert_delete_original_files_message".localized
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let delete = UIAlertAction(title: "delete".localized, style: .destructive) { _ in
                Self.delete(assets: assets)
            }
            
            let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
            alert.addAction(delete)
            alert.addAction(cancel)
                    
            self.viewController?.showDetailViewController(alert, sender: nil)
        case .always:
            Self.delete(assets: assets)
        }
    }
        
    //MARK: - Private
    
    private func showAuthorizationPermissionAlertMain() {
        let title = "alert_error_permission_photos_title".localized
        let message = "alert_error_permission_photos_message".localized
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title:  "ok".localized, style: .default) { (_) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
                return
            }
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
        alert.addAction(ok)
        let cancel = UIAlertAction(title:  "cancel".localized, style: .cancel)
        alert.addAction(cancel)
        self.viewController?.present(alert, animated: true)
    }
    
    private func showAuthorizationPermissionAlert() {
        DispatchQueue.main.async { [weak self] in
            self?.showAuthorizationPermissionAlertMain()
        }
    }
    
    private func open() {
        DispatchQueue.main.async { [weak self] in
            self?.openPickerView()
        }
    }
    
    private func openPickerView() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 200
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        self.viewController?.showDetailViewController(picker, sender: nil)
    }
        
}

extension STPHPhotoHelper: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        let identifiers = results.compactMap({$0.assetIdentifier})
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var result = [PHAsset]()
        fetchResult.enumerateObjects { asset, index, _ in
            result.append(asset)
        }
        
        let countDiff = results.count - result.count
        self.viewController?.pickerViewController(self, didPickAssets: result, failedAssetCount: countDiff)
    }
    
}

extension STPHPhotoHelper {
    
    static private(set) var authorizationStatus: PHAuthorizationStatus?
    
    class func checkAndReqauestAuthorization(queue: DispatchQueue? = nil, completion: @escaping (PHAuthorizationStatus) -> Void) {
        
        if let authorizationStatus = self.authorizationStatus {
            let queue = queue ?? DispatchQueue.main
            queue.async {
                completion(authorizationStatus)
            }
            return
        }
       
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            let queue = queue ?? DispatchQueue.main
            self.authorizationStatus = status
            queue.async {
                completion(status)
            }
        }
    }
    
    class func delete(assets: [PHAsset]) {
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
    
    class func save(items: [(url: URL, itemType: ItemType)], completionHandler: @escaping (() -> Void)) {
        let library = PHPhotoLibrary.shared()
        var count = items.count
        for item in items {
            library.performChanges {
                let _ = item.itemType == .photo ? PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: item.url) :  PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: item.url)
            } completionHandler: { _, error in
                count = count - 1
                if count == .zero {
                    completionHandler()
                }
            }
        }
    }

    class func moveToAlbum(albumName: String, assets: [PHAsset], completion: @escaping (() -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            let assetCollection = self.get(album: albumName)
            if let album = assetCollection.firstObject {
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.addAssets(assets as NSFastEnumeration)
            } else {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                changeRequest.addAssets(assets as NSFastEnumeration)
            }
        } completionHandler: { end, error in
            completion()
        }
    }
    
    class func delete(albumName: String, completion: @escaping ((Bool) -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            let assetCollection = self.get(album: albumName)
            if assetCollection.firstObject != nil {
                PHAssetCollectionChangeRequest.deleteAssetCollections(assetCollection as NSFastEnumeration)
            }
        } completionHandler: { end, error in
            completion(end)
        }
    }
    
    class func deleteFiles(albumName: String, completion: @escaping ((Bool) -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            let assetCollection = self.get(album: albumName)
            if let album = assetCollection.firstObject {
                let assets = PHAsset.fetchAssets(in: album, options: PHFetchOptions())
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            }
        } completionHandler: { end, error in
            completion(end)
        }
    }
    
    class func removeFiles(albumName: String, completion: @escaping ((Bool) -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            let assetCollection = self.get(album: albumName)
            if let album = assetCollection.firstObject {
                let assets = PHAsset.fetchAssets(in: album, options: PHFetchOptions())
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.removeAssets(assets)
            }
        } completionHandler: { end, error in
            completion(end)
        }
    }

    class private func get(album name: String) -> PHFetchResult<PHAssetCollection> {
        let options = PHFetchOptions()
        let predicate = NSPredicate(format: "\(#keyPath(PHAssetCollection.localizedTitle)) == %@", name as CVarArg)
        options.predicate = predicate
        let assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        return assetCollection
    }        
    
}


extension STPHPhotoHelper {
    
    struct PHAssetDataInfo {
        var url: URL
        var videoDuration: TimeInterval
        var fileSize: UInt
        var creationDate: Date?
        var modificationDate: Date?
    }
    
    typealias AssetProgressHandler = (Double, UnsafeMutablePointer<ObjCBool>?) -> Void
    
    private static let phManager = PHImageManager.default()

    class func requestGetURL(asset: PHAsset, progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        switch asset.mediaType {
        case .image:
            self.requestImageAssetInfo(asset: asset, progressHandler: progressHandler, completion: completion)
        case .video:
            self.requestVideoAssetInfo(asset: asset, progressHandler: progressHandler, completion: completion)
        default:
            fatalError("this case not supported")
        }
    }
    
    class func requestThumb(asset: PHAsset, progressHandler: AssetProgressHandler?, completion : @escaping ((_ image: UIImage?) -> Void)) {
        
        let options = PHImageRequestOptions()
        options.version = .current
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        options.progressHandler = { progressValue, error, stop, info in
            progressHandler?(progressValue, stop)
        }
                
        let size = STConstants.thumbSize(for: CGSize(width: asset.pixelWidth, height: asset.pixelHeight))
        self.phManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { thumb, info  in
            progressHandler?(1, nil)
            completion(thumb)
           
        }
    }
    
    //MARK: - Private
    
    private class func requestVideoAssetInfo(asset: PHAsset,  progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        guard asset.mediaType == .video else {
            completion(nil)
            return
        }
        
        let options: PHVideoRequestOptions = PHVideoRequestOptions()

        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, error, stop, info in
            progressHandler?(progress, stop)
        }
        
        let modificationDate = asset.modificationDate ?? asset.creationDate
        let creationDate = asset.creationDate ?? asset.modificationDate

        self.phManager.requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            
            if let urlAsset = asset as? AVURLAsset, let fileSize = urlAsset.fileSize {
                let localVideoUrl: URL = urlAsset.url as URL
                let responseURL: URL = localVideoUrl
                let videoDuration: TimeInterval = urlAsset.duration.seconds
                let fileSize: UInt = UInt(fileSize)
                let result = PHAssetDataInfo(url: responseURL,
                                videoDuration: videoDuration,
                                fileSize: fileSize,
                                creationDate: creationDate,
                                modificationDate: modificationDate)
                
                completion(result)
            } else {
                completion(nil)
            }
        })
    }
    
    private class func requestImageAssetInfo(asset: PHAsset, progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        guard asset.mediaType == .image else {
            completion(nil)
            return
        }
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
            return false
        }
        
        options.progressHandler = { progress, stop in
            progressHandler?(progress, stop)
        }
                
        let modificationDate = asset.modificationDate ?? asset.creationDate
        let creationDate = asset.creationDate ?? asset.modificationDate
        
        asset.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
            guard let contentEditingInput = contentEditingInput, let fullSizeImageURL = contentEditingInput.fullSizeImageURL else {
                completion(nil)
                return
            }
            let responseURL: URL = fullSizeImageURL
            let videoDuration: TimeInterval = .zero
            let creationDate: Date? = creationDate
            let modificationDate: Date? = modificationDate
            
            let attr = try? FileManager.default.attributesOfItem(atPath: responseURL.path)
            let fileSize = (attr?[FileAttributeKey.size] as? UInt) ?? 0
            
            let result = PHAssetDataInfo(url: responseURL,
                            videoDuration: videoDuration,
                            fileSize: fileSize,
                            creationDate: creationDate,
                            modificationDate: modificationDate)
            completion(result)
        })
        
    }
    
}

extension STPHPhotoHelper {

    enum ItemType {
        case photo
        case video
    }

}
