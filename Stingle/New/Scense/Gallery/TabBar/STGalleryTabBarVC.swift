//
//  STGalleryTabBar.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/11/21.
//

import UIKit

class STGalleryTabBarVC: STTabBarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewControllers?.enumerated().forEach({ (vc) in
            vc.element.tabBarItem.title = ControllersTypes(rawValue: vc.offset)?.title
        })
    }
    
    
}

extension STGalleryTabBarVC {
    
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
