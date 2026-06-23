//
//  STGalleryTabBar.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/11/21.
//

import UIKit

class STGalleryTabBarVC: STTabBarViewController {

    private var lastTabBarWidth: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.installCameraTabIfNeeded()
        self.viewControllers?.enumerated().forEach({ (vc) in
            vc.element.tabBarItem.title = ControllersTypes(rawValue: vc.offset)?.title
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Adding the 4th tab in viewDidLoad lays the items out before the bar has
        // its final width (the split/drawer container resizes it later), which
        // wraps/misplaces the titles until something forces a rebuild. When the
        // bar's width actually changes, rebuild the items at that width by
        // re-assigning viewControllers (a plain setNeedsLayout wasn't enough).
        let width = self.tabBar.bounds.width
        guard width > 0, width != self.lastTabBarWidth else { return }
        self.lastTabBarWidth = width
        let selected = self.selectedIndex
        let controllers = self.viewControllers
        self.viewControllers = controllers
        self.selectedIndex = selected
        self.tabBar.setNeedsLayout()
        self.tabBar.layoutIfNeeded()
    }

    private func installCameraTabIfNeeded() {
        guard var controllers = self.viewControllers else { return }
        guard !controllers.contains(where: { ($0 as? UINavigationController)?.viewControllers.first is STCameraVC || $0 is STCameraVC }) else { return }
        // Wrap in a navigation controller like the other tabs so the tab bar lays
        // the item out consistently.
        let camera = STCameraVC()
        let nav = STNavigationController(rootViewController: camera)
        nav.setNavigationBarHidden(true, animated: false)
        nav.tabBarItem = UITabBarItem(title: ControllersTypes.camera.title,
                                      image: UIImage(systemName: "camera"),
                                      selectedImage: UIImage(systemName: "camera.fill"))
        controllers.append(nav)
        self.viewControllers = controllers
    }

}

extension STGalleryTabBarVC {

    enum ControllersTypes: Int {
        case gallery
        case albums
        case sharing
        case camera

        var title: String {
            switch self {
            case .gallery:
                return "gallery".localized
            case .albums:
                return "albums".localized
            case .sharing:
                return "sharing".localized
            case .camera:
                return "camera".localized
            }
        }

    }

}
