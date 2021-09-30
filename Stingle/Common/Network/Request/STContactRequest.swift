//
//  STContactRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/3/21.
//

import Foundation

enum STContactRequest {
    case getContactBy(email: String)
}

extension STContactRequest: IEncryptedRequest {
    
    var bodyParams: [String : Any]? {
        switch self {
        case .getContactBy(let email):
            return ["email": email]
        }
    }
    
    var path: String {
        switch self {
        case .getContactBy:
            return "sync/getContact"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .getContactBy:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .getContactBy:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .getContactBy:
            return STNetworkDispatcher.Encoding.body
        }
    }
    
}
