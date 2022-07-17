//
//  STMainVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit
import StingleRoot

class STMainVC: UIViewController {
	
	private let viewModel = STMainVM()
    private var appInUnauthorized: Bool = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.setupApp { [weak self] (_) in
            self?.configure()
            if self?.appInUnauthorized == true {
                self?.showUnauthorizedAlert()
            } else {
                self?.openAppController()
            }
        }
    }
	
	//MARK: - Private func
	
	private func configure() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .appText
        
        let theme = STAppSettings.current.appearance.theme
        UIView.animate(withDuration: 0.3) {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = theme.interfaceStyle
            }
        }
	}
    
    private func showUnauthorizedAlert() {
        self.showInfoAlert(title: nil, message: "app_unauthorized_message".localized) { [weak self] in
            self?.openAppController()
        }
        
    }
	
	private func openAppController() {
        var identifier = ""
        if self.viewModel.isLogined() {
            if self.viewModel.appIsLocked() {
                identifier = "goToLock"
            } else {
                identifier = "goToApp"
            }
        } else {
            identifier = "goToAuth"
        }
		self.performSegue(withIdentifier: identifier, sender: nil)
	}
    
}

extension STMainVC {
    
    class func show(appInUnauthorized: Bool) {
        
        let storyboard = UIStoryboard(name: "Welcome", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "STMainVCID")
        let window =  UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        (vc as? STMainVC)?.appInUnauthorized = appInUnauthorized
        
        window?.rootViewController = vc
        guard let rootWindow = window else {
            return
        }
        if UIView.areAnimationsEnabled {
            let options: UIView.AnimationOptions = .transitionFlipFromRight
            let duration: TimeInterval = 0.5
            UIView.transition(with: rootWindow, duration: duration, options: options, animations: {
            }, completion:
                                { completed in
            })
        }
        
    }
    
}
