//
//  IRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

enum STRequestMethod : String {
	case POST
	case GET
	case HEAD
	case NOTIMPLEMENTED
	
	func value() -> String {
		return self.rawValue
	}
}

protocol IRequest {
	var url: String { get }
	var method: STNetworkDispatcher.Method { get }
	var headers: [String: String]? { get }
	var parameters: [String: Any]? { get }
	var encoding: STNetworkDispatcher.Encoding { get }
}

protocol STRequest: IRequest {
	var path: String { get }
}

extension STRequest {
	
	var url: String {
		return "\(STEnvironment.current.baseUrl)/\(self.path)"
	}
    
    var token: String? {
        return STApplication.shared.user()?.token
    }
    
}
