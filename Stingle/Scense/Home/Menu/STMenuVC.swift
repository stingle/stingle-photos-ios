//
//  STMenuVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/5/21.
//

import UIKit
import StingleRoot

class STMenuVC: STSplitViewController {
        
    private let masterViewControllerIdentifier = "masterViewController"
    private var controllers = [String: UIViewController]()
    private weak var backupPhraseView: STBackupPhraseView?
    
    lazy private var biometricAuthServices: STBiometricAuthServices = {
        return STBiometricAuthServices()
    }()
    
    var appPassword: String?
    var isShowBackupPhrase: Bool = false
    
    private var isViewDidAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let menu = self.storyboard!.instantiateViewController(identifier: self.masterViewControllerIdentifier) as! IMasterViewController
        self.setMasterViewController(masterViewController: menu, isAnimated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !self.isViewDidAppear else {
            return
        }
        self.isViewDidAppear = true
        self.showIsFirstOpensView()
    }
    
    func setDetailViewController(identifier: String) {
        let detailViewController = self.controllers[identifier] ?? self.storyboard!.instantiateViewController(identifier: identifier)
        if detailViewController.menu(saveInQue: self) {
            self.controllers[identifier] = detailViewController
        }
        self.setDetailViewController(detailViewController: detailViewController, isAnimated: true)
    }
        
    //MARK: - Private methods
    
    private func showIsFirstOpensView() {
        self.showBackupPhraseIfNeeded { [weak self] in
            self?.showBiometricAuthQuestionIfNeeded { [weak self] in
                self?.showAutoImportContollerIfNeeded {
                    STApplication.shared.syncManager.sync(success: nil, failure: nil)
                }
            }
        }
    }
    
    private func showBiometricAuthQuestionIfNeeded(completion: @escaping (() -> Void)) {
        guard let password = self.appPassword, self.biometricAuthServices.state != .notAvailable else {
            completion()
            return
        }
        let biometricAuthTitle = "biometric_authentication".localized
        let biometricAuthMessage = "biometric_authentication_message".localized
        self.showInfoAlert(title: biometricAuthTitle, message: biometricAuthMessage, cancel: true) { [weak self] in
            self?.onBiometricAuth(password: password)
            completion()
        }
        self.appPassword = nil
    }
    
    private func showAutoImportContollerIfNeeded(completion: @escaping (() -> Void)) {
        STAutoImportDialogVC.showDialog(in: self, completion: completion)
    }
    
    private func showBackupPhraseIfNeeded(completion: @escaping (() -> Void)) {
        let isKeyBackedUp = (STApplication.shared.utils.user()?.isKeyBackedUp ?? true)
        guard !isKeyBackedUp, let key = STKeyManagement.key, let mnemonic = try? STMnemonic.mnemonicString(from: key), self.isShowBackupPhrase else {
            completion()
            return
        }
        self.backupPhraseView = STBackupPhraseView.show(in: self.view, text: mnemonic, completion: completion)
        self.backupPhraseView?.delegate = self
        self.isShowBackupPhrase = false
    }
        
    private func onBiometricAuth(password: String) {
        self.biometricAuthServices.onBiometricAuth(password: password, {
            var security = STAppSettings.current.security
            security.authentication.unlock = true
            STAppSettings.current.security = security
        }, failure: nil)
    }
    
    
}


extension STMenuVC: STBackupPhraseViewDelegate {
    
    func backupPhraseView(didSelectCancel backupPhraseView: STBackupPhraseView) {
        backupPhraseView.hide()
    }
    
    func backupPhraseView(didSelectCopy backupPhraseView: STBackupPhraseView, text: String?) {
        backupPhraseView.hide()
        UIPasteboard.general.string = text
    }
    
}


@objc extension UIViewController {
    
    func menu(saveInQue menuVC: STMenuVC) -> Bool {
        return true
    }
    
}
