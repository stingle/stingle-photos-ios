//
//  STMainVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation
import UIKit

class STMainVM {
    
    static private var isAppSetuped: Bool = false
	
	func setupApp(end: ((_ result: Bool) -> Void)) {
        guard !STMainVM.isAppSetuped else {
            end(true)
            return
        }
        STNetworkReachableService.shared.start()
        UIDevice.current.isBatteryMonitoringEnabled = true
        end(true)
	}
	
	func isLogined() -> Bool {
        return STApplication.shared.utils.isLogedIn()
	}
    
    func appIsLocked() -> Bool {
        return STApplication.shared.utils.appIsLocked()
    }
	
}
