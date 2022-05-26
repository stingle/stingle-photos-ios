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
                self.openPhotoPicker()
                break
            default:
                self.showAuthorizationPermissionAlert()
                break
            }
        }
    }
    
    func deleteAssetsAfterManualImport(assets: [PHAsset]) {
        
        guard !assets.isEmpty else {
            return
        }
        
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
    
    private func openPhotoPicker() {
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
    
    private func picker(didFinishPicking results: [PHPickerResult]) {
        let identifiers = results.compactMap({$0.assetIdentifier})
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var result = [PHAsset]()
        fetchResult.enumerateObjects { asset, index, _ in
            result.append(asset)
        }
        let countDiff = results.count - result.count
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.viewController?.pickerViewController(weakSelf, didPickAssets: result, failedAssetCount: countDiff)
        }
    }
        
}

extension STPHPhotoHelper: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            DispatchQueue.global().async { [weak self] in
                self?.picker(didFinishPicking: results)
            }
        }
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
        let dataInfo: URL
        let videoDuration: TimeInterval
        let fileSize: UInt
        let creationDate: Date?
        let modificationDate: Date?
        let freeBuffer: (() -> Void)?
    }
    
    typealias AssetProgressHandler = (Double, UnsafeMutablePointer<ObjCBool>?) -> Void
    
    private static let phManager = PHImageManager.default()

    class func requestGetURL(asset: PHAsset, queue: DispatchQueue?, progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        let queue = queue ?? .main
        
        switch asset.mediaType {
        case .image:
            self.requestImageAssetInfo(asset: asset, queue: queue, progressHandler: progressHandler, completion: completion)
        case .video:
            self.requestVideoAssetInfo(asset: asset, queue: queue, progressHandler: progressHandler, completion: completion)
        default:
            fatalError("this case not supported")
        }
    }
    
    class func requestThumb(asset: PHAsset, queue: DispatchQueue?, progressHandler: AssetProgressHandler?, completion : @escaping ((_ image: UIImage?) -> Void)) {
        
        let queue = queue ?? .main
        
        let options = PHImageRequestOptions()
        options.version = .current
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        var isStoped = false
        options.progressHandler = { progressValue, error, stop, info in
            progressHandler?(progressValue, stop)
            if isStoped == false {
                isStoped = stop.pointee.boolValue
            }
        }
                
        let size = STConstants.thumbSize(for: CGSize(width: asset.pixelWidth, height: asset.pixelHeight))
        
        
        self.phManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { thumb, info  in
            queue.async {
                progressHandler?(1, nil)
                guard !isStoped else {
                    completion(nil)
                    return
                }
                completion(thumb)
            }
        }
    }
    
    //MARK: - Private
    
    private class func requestVideoAssetInfo(asset: PHAsset, queue: DispatchQueue,  progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        guard asset.mediaType == .video else {
            completion(nil)
            return
        }
        
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        var isStoped = false
        
        options.progressHandler = { progress, error, stop, info in
            progressHandler?(progress, stop)
            if isStoped == false {
                isStoped = stop.pointee.boolValue
            }
        }
        
        let modificationDate = asset.modificationDate ?? asset.creationDate
        let creationDate = asset.creationDate ?? asset.modificationDate

        self.phManager.requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                        
            if let urlAsset = asset as? AVURLAsset, let fileSize = urlAsset.fileSize {
                
                guard !isStoped else {
                    queue.async {
                        completion(nil)
                    }
                    return
                }
                
                let localVideoUrl: URL = urlAsset.url as URL
                let responseURL: URL = localVideoUrl
                let videoDuration: TimeInterval = urlAsset.duration.seconds
                let fileSize: UInt = UInt(fileSize)
                let result = PHAssetDataInfo(dataInfo: responseURL,
                                             videoDuration: videoDuration,
                                             fileSize: fileSize,
                                             creationDate: creationDate,
                                             modificationDate: modificationDate, freeBuffer: nil)
                queue.async {
                    completion(result)
                }
            } else {
                queue.async {
                    completion(nil)
                }
            }
        })
    }
    
    private class func requestContentEditingAssetInfo(asset: PHAsset, queue: DispatchQueue, progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        guard asset.mediaType == .image else {
            queue.async {
                completion(nil)
            }
            return
        }
        
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
            return false
        }
        
        var isStoped = false
        options.progressHandler = { progress, stop in
            progressHandler?(progress, stop)
            if isStoped == false {
                isStoped = stop.pointee.boolValue
            }
        }
                
        let modificationDate = asset.modificationDate ?? asset.creationDate
        let creationDate = asset.creationDate ?? asset.modificationDate
                
        asset.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
            
            guard !isStoped else {
                queue.async {
                    completion(nil)
                }
                return
            }
            
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
                        
            let result = PHAssetDataInfo(dataInfo: responseURL,
                                         videoDuration: videoDuration,
                                         fileSize: fileSize,
                                         creationDate: creationDate,
                                         modificationDate: modificationDate,
                                        freeBuffer: nil)
            queue.async {
                completion(result)
            }
        })
        
    }
    
    private class func requestImageAssetInfo(asset: PHAsset, queue: DispatchQueue, progressHandler: AssetProgressHandler?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
                
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
        
            queue.async {
                completion(nil)
            }
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.isSynchronous = false
        
        var isStoped = false
        options.progressHandler = { progressValue, error, stop, info in
            progressHandler?(progressValue, stop)
            if isStoped == false {
                isStoped = stop.pointee.boolValue
            }
        }
                
        let modificationDate = asset.modificationDate ?? asset.creationDate
        let creationDate = asset.creationDate ?? asset.modificationDate
        
        self.phManager.requestImageDataAndOrientation(for: asset, options: options) { imageData, param, orientation, info in
            
            queue.async {
                guard let imageData = imageData else {
                    completion(nil)
                    return
                }
                
                let fileManager = FileManager.default
                var url = fileManager.temporaryDirectory
                url.appendPathComponent("asset.request.image")
                let uuID = UUID().uuidString
                url.appendPathComponent(uuID)
                let removeUrl = url
                url.appendPathComponent(resource.originalFilename)

                do {
                    try fileManager.createDirectory(at: removeUrl, withIntermediateDirectories: true, attributes: nil)
                    try imageData.write(to: url)

                    let responseURL: URL = url
                    let videoDuration: TimeInterval = .zero
                    let creationDate: Date? = creationDate
                    let modificationDate: Date? = modificationDate
                    let fileSize = UInt(imageData.count)

                    let freeBuffer: (() -> Void)? = {
                        try? fileManager.removeItem(at: removeUrl)
                    }

                    let result = PHAssetDataInfo(dataInfo: responseURL,
                                                 videoDuration: videoDuration,
                                                 fileSize: fileSize,
                                                 creationDate: creationDate,
                                                 modificationDate: modificationDate,
                                                 freeBuffer: freeBuffer)
                    completion(result)
                } catch {
                    completion(nil)
                }

            }

        }
        
    }
    
    
    
}

extension STPHPhotoHelper {

    enum ItemType {
        case photo
        case video
    }

}
