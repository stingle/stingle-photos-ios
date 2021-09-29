//
//  STResponse.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

class STResponse<T: Decodable>: IResponse {
	
	private enum CodingKeys: String, CodingKey {
		case status = "status"
		case parts = "parts"
		case infos = "infos"
		case errors = "errors"
	}
	
	var status: String
	var parts: T?
	var infos: [String]
	var errors: [String]
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.status = try container.decode(String.self, forKey: .status)
		self.parts = try? container.decodeIfPresent(T.self, forKey: .parts)
		self.infos = try container.decode([String].self, forKey: .infos)
		self.errors = try container.decode([String].self, forKey: .errors)
	}
}

struct STEmptyResponse: Codable {
    
}

struct STLogoutResponse: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case logout = "logout"
    }
    
    let logout: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.logout = (try? container.decodeIfPresent(Int.self, forKey: .logout) ?? .zero) == 1
    }
    
}
