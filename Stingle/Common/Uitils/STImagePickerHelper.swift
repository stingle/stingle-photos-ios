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
    func pickerViewController(_ imagePickerHelper: STImagePickerHelper, didPickAssets assets: [PHAsset], failedAssetCount: Int)
    func pickerViewControllerDidCancel(_ imagePickerHelper: STImagePickerHelper)
}

extension STImagePickerHelperDelegate {
    func pickerViewControllerDidCancel(_ imagePickerHelper: STImagePickerHelper) {}
    func pickerViewController(_ imagePickerHelper: STImagePickerHelper, didPickAssets assets: [PHAsset]) {}
}

class STImagePickerHelper: NSObject {
    
    weak var viewController: STImagePickerHelperDelegate?
        
    init(controller: STImagePickerHelperDelegate?) {
        self.viewController = controller
    }
    
    func openPicker() {
        self.checkAndReqauestAuthorization { (status) in
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
    
    func save(items: [(url: URL, itemType: ItemType)], completionHandler: @escaping (() -> Void) ) {
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
    
    func delete(assets: [PHAsset]) {
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
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
    
    private func checkAndReqauestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined  {
            PHPhotoLibrary.requestAuthorization({status in
                completion(status)
            })
        } else {
            completion(status)
        }
    }
    
}

extension STImagePickerHelper: PHPickerViewControllerDelegate {
    
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

extension STImagePickerHelper {

    enum ItemType {
        case photo
        case video
    }

}
