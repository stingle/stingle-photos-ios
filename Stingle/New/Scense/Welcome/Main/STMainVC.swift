//
//  STMainVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

class STMainVC: UIViewController {
	
	private let viewModel = STMainVM()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.configure()
		self.viewModel.setupApp { [weak self] (_) in
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self?.openAppController()
			}
		}
    }
	
	//MARK: - Private func
	
	private func configure() {
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
    
    class func show() {
        
        let storyboard = UIStoryboard(name: "Welcome", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "STMainVCID")
        let window =  UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        
        if let rootVC = window?.rootViewController {
            let segue = STRootWindowSegue(identifier: "STMainVCID", source: rootVC, destination: vc)
            segue.perform()
        } else {
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
    
}
