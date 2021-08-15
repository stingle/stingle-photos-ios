//
//  STAuthRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

enum STAuthRequest {
	case register(email: String, password: String, salt: String, keyBundle: String, isBackup: Bool)
	case preLogin(email: String)
	case login(email: String, password: String)
    case checkRecoveryPhrase(email: String)
}

extension STAuthRequest: STRequest {
	
	var path: String {
		switch self {
		case .register:
			return "register/createAccount"
		case .preLogin:
			return "login/preLogin"
		case .login:
			return "login/login"
        case .checkRecoveryPhrase:
            return "login/checkKey"
		}
	}
	
	var method: STNetworkDispatcher.Method {
		switch self {
		case .register:
			return .post
		case .preLogin:
			return .post
		case .login:
			return .post
        case .checkRecoveryPhrase:
            return .post
		}
	}
	
	var headers: [String : String]? {
		switch self {
		case .register:
			return nil
		case .preLogin:
			return nil
		case .login:
			return nil
        case .checkRecoveryPhrase:
            return nil
		}
	}
	
	var parameters: [String : Any]? {
		switch self {
		case .register(let email, let password, let salt, let keyBundle, let isBackup):
			let isBackup = isBackup ? "1" : "0"
			return ["email": email, "password": password, "salt": salt, "keyBundle": keyBundle, "isBackup": isBackup]
		case .preLogin(let email):
			return ["email": email]
		case .login(let email, let password):
			return ["email": email, "password": password]
        case .checkRecoveryPhrase(let email):
            return ["email": email]
		}
	}
	
	var encoding: STNetworkDispatcher.Encoding {
		switch self {
		case .register:
			return STNetworkDispatcher.Encoding.body
		case .preLogin:
			return STNetworkDispatcher.Encoding.body
		case .login:
			return STNetworkDispatcher.Encoding.body
        case .checkRecoveryPhrase:
            return STNetworkDispatcher.Encoding.body
		}
	}
	
}
