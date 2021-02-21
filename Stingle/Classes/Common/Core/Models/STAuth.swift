//
//  STSignUp.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/18/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

enum STAuth {
	
	struct Register: Codable {
		var homeFolder: String
		var token: String
		var userId: String
	}

	struct Login : Codable {
		var salt:String
	}
	
}




