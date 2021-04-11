//
//  STImagePickerHelper.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import UIKit
import Photos
import Tatsi

protocol STImagePickerHelperDelegate: UIViewController {
    func pickerViewController(_ imagePickerHelper: STImagePickerHelper, didPickAssets assets: [PHAsset])
    func pickerViewControllerDidCancel(_ imagePickerHelper: STImagePickerHelper)
}

extension STImagePickerHelperDelegate {
    func pickerViewControllerDidCancel(_ imagePickerHelper: STImagePickerHelper) {}
}

class STImagePickerHelper: NSObject {
    
    weak var viewController: STImagePickerHelperDelegate?
        
    init(controller: STImagePickerHelperDelegate) {
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
            self?.openTatsiPickerView()
        }
    }
    
    private func openTatsiPickerView() {
        var config = TatsiConfig.default
        config.supportedMediaTypes = [.video, .image]
        config.maxNumberOfSelections = 200
        let pickerViewController = TatsiPickerViewController(config: config)
        pickerViewController.pickerDelegate = self
        self.viewController?.present(pickerViewController, animated: true, completion: nil)
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

extension STImagePickerHelper: TatsiPickerViewControllerDelegate {
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didPickAssets assets: [PHAsset]) {
        self.viewController?.pickerViewController(self, didPickAssets: assets)
    }
    
    func pickerViewControllerDidCancel(_ pickerViewController: TatsiPickerViewController) {
        self.viewController?.pickerViewControllerDidCancel(self)
    }
    
}
