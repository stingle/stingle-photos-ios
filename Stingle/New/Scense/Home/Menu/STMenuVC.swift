//
//  STMenuVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/5/21.
//

import UIKit

class STMenuVC: STSplitViewController {
    
    private let masterViewControllerIdentifier = "masterViewController"
    private var controllers = [String: UIViewController]()
    
    lazy private var biometricAuthServices: STBiometricAuthServices = {
        return STBiometricAuthServices()
    }()
    
    var appPassword: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        let menu = self.storyboard!.instantiateViewController(identifier: self.masterViewControllerIdentifier) as! IMasterViewController
        self.setMasterViewController(masterViewController: menu, isAnimated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showBiometricAuthQuestionIfNeeded()
    }
    
    func setDetailViewController(identifier: String) {
        let detailViewController = self.controllers[identifier] ?? self.storyboard!.instantiateViewController(identifier: identifier)
        self.controllers[identifier] = detailViewController
        self.setDetailViewController(detailViewController: detailViewController, isAnimated: true)
    }
    
    //MARK: - Private methods
    
    private func showBiometricAuthQuestionIfNeeded() {
        guard let password = self.appPassword, self.biometricAuthServices.state != .notAvailable else {
            return
        }
        let biometricAuthTitle = "biometric_authentication".localized
        let biometricAuthMessage = "biometric_authentication_message".localized
        self.showOkCancelAlert(title: biometricAuthTitle, message: biometricAuthMessage, handler: { [weak self] _ in
            self?.onBiometricAuth(password: password)
        }, cancel: nil)
        self.appPassword = nil
    }
    
    private func onBiometricAuth(password: String) {
        self.biometricAuthServices.onBiometricAuth(password: password, {
            var security = STAppSettings.security
            security.authentication.unlock = true
            STAppSettings.security = security
        }, failure: nil)
    }
    
}
