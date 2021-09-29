//
//  STBillingRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

enum STBillingRequest {
    case billingInfo(rand: String)
}

extension STBillingRequest: IEncryptedRequest {

    var path: String {
        return "billing/info"
    }

    var bodyParams: [String : Any]? {
        switch self {
        case .billingInfo(let rand):
            return ["rand": rand]
        }
    }
    
}
