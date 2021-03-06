//
//  STTabBarViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/4/21.
//

import UIKit

class STTabBarVC: UITabBarController {
    
    let syncWorker = STSyncWorker()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        syncWorker.getUpdates()
        

        // Do any additional setup after loading the view.
    }
    

}
