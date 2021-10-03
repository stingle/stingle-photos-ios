//
//  STNavigationController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/17/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

class STNavigationController: UINavigationController {
    
    @IBInspectable var saveInMenuQue: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance
    }
    
    override func menu(saveInQue menuVC: STMenuVC) -> Bool {
        return self.saveInMenuQue
    }
	
	override init(rootViewController: UIViewController) {
		super.init(rootViewController: rootViewController)
		self.updateNavigationBar(for: rootViewController)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		if let first = self.viewControllers.first {
			self.updateNavigationBar(for: first, animated: false)
		}
	}
    
    override var viewControllers: [UIViewController] {
        didSet {
            if let first = self.viewControllers.first {
                self.updateNavigationBar(for: first)
            }
            self.updateSplitViewController()
        }
    }
    
    override var splitMenuViewController: STSplitViewController? {
        didSet {
            self.updateSplitViewController()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.topViewController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.topViewController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.interactivePopGestureRecognizer?.delegate = self
	}
	
	override var shouldAutorotate: Bool {
		return self.topViewController?.shouldAutorotate ?? super.shouldAutorotate
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return self.topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return self.topViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
	}
		
	override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
		super.setViewControllers(viewControllers, animated: animated)
		if let first = viewControllers.first {
			self.updateNavigationBar(for: first)
		}
	}
   
	override func pushViewController(_ viewController: UIViewController, animated: Bool) {
		super.pushViewController(viewController, animated: animated)
		self.updateNavigationBar(for: viewController)
	}
	
	override func popViewController(animated: Bool) -> UIViewController? {
		if self.viewControllers.count - 2 >= 0 {
			self.updateNavigationBar(for: self.viewControllers[self.viewControllers.count - 2])
		}
		return super.popViewController(animated: animated)
	}
	
	override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
		self.updateNavigationBar(for: viewController)
		return super.popToViewController(viewController, animated: animated)
	}
	
	override func popToRootViewController(animated: Bool) -> [UIViewController]? {
		if let first = self.viewControllers.first {
			self.updateNavigationBar(for: first)
		}
		return super.popToRootViewController(animated: animated)
	}
        
    //MARK: - private
	
	private func updateNavigationBar(for viewController: UIViewController, animated: Bool = true) {
		let isNavigationBarHidden = viewController.isNavigationBarHidden()
		if self.isNavigationBarHidden != isNavigationBarHidden {
			self.setNavigationBarHidden(isNavigationBarHidden, animated: animated)
		}
	}
    
    private func updateSplitViewController() {
        self.viewControllers.forEach { (vc) in
            if vc.splitMenuViewController != self.splitMenuViewController {
                vc.splitMenuViewController = self.splitMenuViewController
            }
        }
    }
}

extension STNavigationController: UIGestureRecognizerDelegate {
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		return self.viewControllers.count > 1
	}
	
}

@objc extension UIViewController {
	
	func isNavigationBarHidden() -> Bool {
		return false
	}
		
}
