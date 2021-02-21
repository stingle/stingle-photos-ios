//
//  STMainVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

class STMainVM {
	
	func setupApp(end: ((_ result: Bool) -> Void)) {
		end(true)
	}
	
	func isLogined() -> Bool {
		return SPApplication.isLogedIn()
	}
	
	
}
