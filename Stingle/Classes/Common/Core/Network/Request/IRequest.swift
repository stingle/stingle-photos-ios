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

enum HTTPMethod: String {
	case get     = "GET"
	case post    = "POST"
	case put     = "PUT"
	case patch   = "PATCH"
	case delete  = "DELETE"
}

protocol RequestEncoding {
	func encode(_ urlRequest: URLRequest, with parameters: [String: String?]?) throws -> URLRequest
}

protocol IRequest {
	var url: String { get }
	var method: HTTPMethod { get }
	var headers: [String: String]? { get }
	var parameters: [String: String]? { get }
	var decoder: IDecoder { get }
	var encoding: RequestEncoding { get }
}

fileprivate struct STEnviorment {
//	static let baseUrl = "https://api.stingle.org/v2"
	static let baseUrl = "https://apidev.stingle.org"
}

protocol STRequest: IRequest {
	var path: String { get }
}

extension STRequest {
	
	var url: String {
		return "\(STEnviorment.baseUrl)/\(self.path)"
	}
	
}
