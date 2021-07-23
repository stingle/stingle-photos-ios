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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUi()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.unlockAppBiometric(completion: nil)
    }
    
    //MARK: User Action

    @IBAction private func didSelectLogOutButton(_ sender: Any) {
        
    }
    
    @IBAction private func didSelectUnlockButton(_ sender: Any) {
        
    }
    
    @IBAction private func didBiometricAuthButton(_ sender: Any) {
        self.unlockAppBiometric { [weak self] error in
            guard let error = error else {
                return
            }
            self?.showError(error: error)
        }
    }
    
    private func showConfirmPasswordAlert(completion: @escaping (IError?) -> Void) {
        self.showOkCancelAlert(title: "confirm_password".localized, message: nil, textFieldHandler: { textField in
            textField.isSecureTextEntry = true
        }, handler: { [weak self] password in
            do {
                try self?.viewModel.confirmBiometricPassword(password: password)
                completion(nil)
            } catch {
                completion(STError.error(error: error))
            }
        }, cancel: nil)
        
    }
    
    private func configureUi() {
        self.configureBiometricAuthButton()
        self.configureLocalized()
    }
    
    private func configureBiometricAuthButton() {
        self.biometricAuthButton.isHidden = self.viewModel.biometric.state == .notAvailable
        let imageName = self.viewModel.biometric.type == .faceID ? "ic_face_id" : "ic_touch_id"
        self.biometricAuthButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    private func configureLocalized() {
        self.descriptionLabel.text = "XXXXXXX XXXX XXXXXX XXXXXX".localized
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
    
    private func unlockAppBiometric(completion: ( (IError?) -> Void)?) {
        self.viewModel.unlockAppBiometric { [weak self] confirmpassword in
            if confirmpassword {
                self?.showConfirmPasswordAlert(completion: { error in
                    completion?(error)
                    if error == nil {
                        self?.appDidUnlocked()
                    }
                })
            } else {
                completion?(nil)
                self?.appDidUnlocked()
            }
        } failure: { error in
            completion?(error)
        }
    }
    
}

extension STUnlockAppVC {
    
    class func show() {
        let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        let oldVC = window?.rootViewController
        let storyboard = UIStoryboard(name: "Welcome", bundle: .main)
        let vc = (storyboard.instantiateViewController(withIdentifier: "STUnlockAppVCID") as! STUnlockAppVC)
        vc.currentViewController = oldVC
        window?.rootViewController = vc
    }
    
}
