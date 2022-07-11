//
//  STSignUp.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/18/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

public enum STAuth {
	
    public struct Register: Codable {
		var homeFolder: String
		var token: String
		var userId: String
	}
	
    public struct PreLogin: Codable {
		var salt: String
	}
	
    public struct Login: Codable {
		var homeFolder: String
		var isKeyBackedUp: Int
		var keyBundle: String
		var serverPublicKey: String
		var token: String
		var userId: String
	}
    
    public struct Challenge: Codable {
        var challenge: String
        var isKeyBackedUp: Int
        var serverPK: String
    }
    			
}
