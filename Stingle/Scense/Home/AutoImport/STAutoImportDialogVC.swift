//
//  STAutoImportDialogVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 12/28/21.
//

import UIKit

class STAutoImportDialogVC: STAlertViewController {

    @IBOutlet weak private var contanierView: UIView!
    private var tableViewController: STAutoImportDialogTableVC!
    private var completion: (() -> Void)?
    private var viewModel = ViewModel()
    
    override func presentationController(didSelectBackgroundView presentationController: STAlertPresentationController) {
        self.dismiss()
    }

    override func presentationController(preferredContentSize presentationController: STAlertPresentationController, sourceSize: CGSize, traitCollection: UITraitCollection) -> CGSize {
        return self.tableViewController.view.systemLayoutSizeFitting(sourceSize)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tableViewController" {
            self.tableViewController = segue.destination as? STAutoImportDialogTableVC
            self.tableViewController.delegate = self
        }
    }
    
    //MARK: - Private methods
    
    private func show(error: ImportDialogError) {
        switch error {
        case .phAuthorizationStatus:
            Self.showPhotoAccessDeniedAlert(in: self, actionHandler: nil)
        }
    }
    
    private func dismiss() {   
        self.dismiss(animated: true) { [weak self] in
            self?.completion?()
            self?.completion = nil
        }
    }

}

extension STAutoImportDialogVC: STAutoImportDialogTableVCDelegate {
        
    func autoImportDialogTableVC(didChanged dialogTableVC: STAutoImportDialogTableVC, contentSize: CGSize) {
        self.updatePresentedFrame()
    }
    
    func autoImportDialogTableVC(didSelectSkip dialogTableVC: STAutoImportDialogTableVC) {
        self.viewModel.autoImportDidChange(isOn: false) { [weak self] error in
            if let error = error {
                self?.show(error: error)
            } else {
                self?.dismiss()
            }
        }
    }
    
    func autoImportDialogTableVC(didSelectOnImport dialogTableVC: STAutoImportDialogTableVC) {
        self.viewModel.autoImportDidChange(isOn: true) { [weak self] error in
            if let error = error {
                self?.show(error: error)
            } else {
                self?.dismiss()
            }
        }
    }
    
    func autoImportDialogTableVC(didSelectDeleteOreginalFilesSwich dialogTableVC: STAutoImportDialogTableVC, isOn: Bool) {
        self.viewModel.deleteOriginalFilesAfterAutoImportDidChange(isOn: isOn)
    }
    
    func autoImportDialogTableVC(didSelectImporsExistingFilesSwich dialogTableVC: STAutoImportDialogTableVC, isOn: Bool) {
        self.viewModel.didSelectImporsExistingFilesSwichDidChange(isOn: isOn)
    }
    
}

extension STAutoImportDialogVC {
        
    class func create(completion: @escaping (() -> Void)) -> STAutoImportDialogVC {
        let storyboard = UIStoryboard(name: "Home", bundle: .main)
        let result = storyboard.instantiateViewController(withIdentifier: "STAutoImportDialogVCID") as! STAutoImportDialogVC
        result.completion = completion
        return result
    }
    
    class func showPhotoAccessDeniedAlert(in viewController: UIViewController, actionHandler: (() -> Void)?) {
        
        let message = ImportDialogError.phAuthorizationStatus.message
        
        let okAction: (title: String, handler: (() -> Void)?) = ("settings".localized, {
            actionHandler?()
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
                return
            }
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        })
        
        let cancelAction: (title: String, handler: (() -> Void)?) = (title: "cancel".localized, handler: {
            actionHandler?()
        })
        
        viewController.showOkCancelAlert(title: "warning".localized, message: message, ok: okAction, cancel: cancelAction)
    }
    
    class func showDialog(in viewController: UIViewController, completion: @escaping (() -> Void)) {
        
        ViewModel.calculateAutoImportSetupType { setupType in
            switch setupType {
            case .setuped:
                completion()
            case .noSetuped:
                let dialog = self.create(completion: completion)
                viewController.show(dialog, sender: nil)
            case .photoAccessDenied:
                self.showPhotoAccessDeniedAlert(in: viewController, actionHandler: completion)
            }
        }
        
    }
    
}

