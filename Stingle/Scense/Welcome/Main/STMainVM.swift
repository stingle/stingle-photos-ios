//
//  STMainVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation
import UIKit
import StingleRoot

class STMainVM {
    
    static private var isAppSetuped: Bool = false
	
	func setupApp(end: @escaping ((_ result: Bool) -> Void)) {
        guard !STMainVM.isAppSetuped else {
            end(true)
            return
        }
        STNetworkReachableService.shared.start()
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        STApplication.shared.configure {
            DispatchQueue.main.async {
                end(true)
            }
        }
        
	}
	
	func isLogined() -> Bool {
        return STApplication.shared.utils.isLogedIn()
	}
    
    func appIsLocked() -> Bool {
        return STApplication.shared.utils.appIsLocked()
    }
	
}
