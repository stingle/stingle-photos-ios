//
//  STUserRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/29/21.
//

import Foundation

enum STUserRequest {
    case updateBackcupKeys(keyBundle: String)
    case changePassword(keyBundle: String, newPasswordHash: String, newPasswordSalt: String)
    case deleteAccount(loginHash: String)
    
}

extension STUserRequest: IEncryptedRequest {
    
    var bodyParams: [String : Any]? {
        switch self {
        case .updateBackcupKeys(let keyBundle):
            return ["keyBundle": keyBundle]
        case .changePassword(let keyBundle, let newPasswordHash, let newPasswordSalt):
            return ["keyBundle": keyBundle, "newPassword": newPasswordHash, "newSalt": newPasswordSalt]
        case .deleteAccount(let loginHash):
            return ["password": loginHash]
        }
    }
    
    var path: String {
        switch self {
        case .updateBackcupKeys:
            return "keys/reuploadKeys"
        case .changePassword:
            return "login/changePass"
        case .deleteAccount:
            return "login/deleteUser"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .updateBackcupKeys:
            return .post
        case .changePassword:
            return .post
        case .deleteAccount:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .updateBackcupKeys:
            return nil
        case .changePassword:
            return nil
        case .deleteAccount:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .updateBackcupKeys:
            return STNetworkDispatcher.Encoding.body
        case .changePassword:
            return STNetworkDispatcher.Encoding.body
        case .deleteAccount:
            return STNetworkDispatcher.Encoding.body
        }
    }
    
    var setToken: Bool {
        return true
    }
    
}
