//
//  STMainVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation
//import netfox
import Kingfisher

class STMainVM {
	
	func setupApp(end: ((_ result: Bool) -> Void)) {
//        NFX.sharedInstance().start()
		end(true)
	}
	
	func isLogined() -> Bool {
        return STApplication.shared.isLogedIn()
	}
    
    func appIsLocked() -> Bool {
        return STApplication.shared.appIsLocked()
    }
	
}
