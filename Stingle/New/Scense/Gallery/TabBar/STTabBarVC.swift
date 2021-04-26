//
//  STTabBarViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/4/21.
//

import UIKit

class STTabBarVC: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewControllers?.enumerated().forEach({ (vc) in
            vc.element.tabBarItem.title = ControllersTypes(rawValue: vc.offset)?.title
        })
    }
    
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

extension STTabBarVC {
    
    enum ControllersTypes: Int {
        case gallery
        case albums
        case sharing
        
        var title: String {
            switch self {
            case .gallery:
                return "gallery".localized
            case .albums:
                return "albums".localized
            case .sharing:
                return "sharing".localized
            }
        }
        
    }
    
}


