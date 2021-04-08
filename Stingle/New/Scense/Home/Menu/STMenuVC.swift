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

    override func viewDidLoad() {
        super.viewDidLoad()
        let menu = self.storyboard!.instantiateViewController(identifier: self.masterViewControllerIdentifier) as! IMasterViewController
        self.setMasterViewController(masterViewController: menu, isAnimated: false)
    }
    
    func setDetailViewController(identifier: String) {
        let detailViewController = self.controllers[identifier] ?? self.storyboard!.instantiateViewController(identifier: identifier)
        self.controllers[identifier] = detailViewController
        self.setDetailViewController(detailViewController: detailViewController, isAnimated: true)
    }

}
