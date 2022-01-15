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
        try? PHPhotoLibrary.shared().performChangesAndWait {
            
            let options = PHFetchOptions()
            let predicate = NSPredicate(format: "\(#keyPath(PHAssetCollection.localizedTitle)) == %@", albumName as CVarArg)
            options.predicate = predicate
            
            let assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            
            if let album = assetCollection.firstObject {
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.addAssets(assets as NSFastEnumeration)
            } else {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                changeRequest.addAssets(assets as NSFastEnumeration)
            }
            completion()
   
        }
    }
    
    class func deleteFiles(albumName: String, completion: @escaping ((Bool) -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            let options = PHFetchOptions()
            let predicate = NSPredicate(format: "\(#keyPath(PHAssetCollection.localizedTitle)) == %@", albumName as CVarArg)
            options.predicate = predicate
            let assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            if let album = assetCollection.firstObject {
                let assets = PHAsset.fetchAssets(in: album, options: PHFetchOptions())
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            }
        } completionHandler: { end, error in
            completion(end)
        }
                
    }
    
}

extension STPHPhotoHelper {

    enum ItemType {
        case photo
        case video
    }

}
