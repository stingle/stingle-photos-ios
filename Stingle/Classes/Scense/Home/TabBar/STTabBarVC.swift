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
        
        syncWorker.getUpdates { (_) in
           
        } failure: { (error) in
            
        }

        
       
        

        // Do any additional setup after loading the view.
    }
    

}
