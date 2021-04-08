//
//  STTabBarViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/4/21.
//

import UIKit

class STTabBarVC: UITabBarController {
    
    override var viewControllers: [UIViewController]? {
        didSet {
            self.updateSplitViewController()
        }
    }
    
    override var splitMenuViewController: STSplitViewController? {
        didSet {
            self.updateSplitViewController()
        }
    }

    override func isNavigationBarHidden() -> Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return self.selectedViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.selectedViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.selectedViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
    
    private func updateSplitViewController() {
        self.viewControllers?.forEach { (vc) in
            if vc.splitMenuViewController != self.splitMenuViewController {
                vc.splitMenuViewController = self.splitMenuViewController
            }
        }
    }
    
}
