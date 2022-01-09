//
//  STUnlockAppVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/22/21.
//

import UIKit

class STUnlockAppVC: UIViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var biometricAuthButton: UIButton!
    
    private var currentViewController: UIViewController?
    private var viewModel = STUnlockAppVM()
    
    private var showBiometricUnlocer = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUi()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.showBiometricUnlocer else {
            return
        }
        
        self.unlockApp { [weak self] error in
            guard let error = error else {
                return
            }
            self?.showError(error: error)
        }
    }
    
    //MARK: User Action
    
    @IBAction private func didSelectCameraButton(_ sender: Any) {
//        self.pickerHelper.openCamera()
    }
    
    @IBAction private func didSelectLogOutButton(_ sender: Any) {
        let title = "alert_log_out_title".localized
        let message = "alert_log_out_message".localized
        self.showOkCancelTextAlert(title: title, message: message, textFieldHandler: nil, handler: { [weak self] _ in
            self?.viewModel.logOutApp()
        }, cancel: nil)
        
    }
    
    @IBAction private func didSelectUnlockButton(_ sender: Any) {
        self.unlockApp { [weak self] error in
            guard let error = error else {
                return
            }
            self?.showError(error: error)
        }
    }
    
    @IBAction private func didBiometricAuthButton(_ sender: Any) {
        self.unlockApp { [weak self] error in
            guard let error = error else {
                return
            }
            self?.showError(error: error)
        }
    }
    
    private func showPasswordAlert(completion: @escaping (_ password: String?) -> Void) {
        self.showOkCancelTextAlert(title: "confirm_password".localized, message: nil, textFieldHandler: { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "password".localized
        }, handler: { password in
            completion(password)
        }, cancel: nil)
    }
   
    private func showImputPasswordAlert(completion: @escaping (IError?) -> Void) {
        self.showPasswordAlert { [weak self] password in
            self?.viewModel.unlockApp(password: password, completion: { error in
                completion(error)
            })
        }
    }
    
    private func configureUi() {
        self.configureBiometricAuthButton()
        self.configureLocalized()
    }
    
    private func configureBiometricAuthButton() {
        self.biometricAuthButton.isHidden = !self.viewModel.canUnlockAppBiometric
        let imageName = self.viewModel.biometric.type == .faceID ? "ic_face_id" : "ic_touch_id"
        self.biometricAuthButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    private func configureLocalized() {
        self.descriptionLabel.text = nil
        self.logOutButton.setTitle("log_out".localized, for: .normal)
        self.unlockButton.setTitle("unlock".localized, for: .normal)
    }
    
    private func appDidUnlocked() {
        if let currentViewController = self.currentViewController {
            let windowSegue = STRootWindowSegue(identifier: "goToHome", source: self, destination: currentViewController)
            windowSegue.perform()
        } else {
            self.performSegue(withIdentifier: "goToHome", sender: nil)
        }
    }
        
    private func unlockApp(completion: ( (IError?) -> Void)?) {
        if self.viewModel.canUnlockAppBiometric {
            self.unlockAppBiometric(completion: completion)
        } else {
            self.unlockAppPassword(completion: completion)
        }
    }
    
    private func unlockAppPassword(completion: ( (IError?) -> Void)?) {
        self.showImputPasswordAlert { [weak self] error in
            completion?(error)
            if error == nil {
                self?.appDidUnlocked()
            }
        }
    }
    
    private func unlockAppBiometric(completion: ( (IError?) -> Void)?) {
        self.viewModel.unlockAppBiometric { [weak self] in
            completion?(nil)
            self?.appDidUnlocked()
        } failure: { error in
            completion?(error)
        }
    }
    
}

extension STUnlockAppVC {
    
    class func show(showBiometricUnlocer: Bool) {
        let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        let oldVC = window?.rootViewController
        let storyboard = UIStoryboard(name: "Welcome", bundle: .main)
        let vc = (storyboard.instantiateViewController(withIdentifier: "STUnlockAppVCID") as! STUnlockAppVC)
        vc.currentViewController = oldVC
        vc.showBiometricUnlocer = showBiometricUnlocer
        window?.rootViewController = vc
    }
    
}
