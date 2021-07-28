//
//  STUserRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/29/21.
//

import Foundation

enum STUserRequest {
    case updateBackcupKeys(keyBundle: String)
}

extension STUserRequest: IEncryptedRequest {
    
    var bodyParams: [String : Any]? {
        switch self {
        case .updateBackcupKeys(let keyBundle):
            return ["keyBundle": keyBundle, "token": self.token ?? ""]
        }
    }
    
    var path: String {
        switch self {
        case .updateBackcupKeys:
            return "keys/reuploadKeys"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .updateBackcupKeys:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .updateBackcupKeys:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .updateBackcupKeys:
            return STNetworkDispatcher.Encoding.body
        }
    }
    
}
