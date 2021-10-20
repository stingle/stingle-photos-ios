//
//  STBillingRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

enum STBillingRequest {
    case billingInfo(rand: String)
    case verifi(transactions: Transactions)
}

extension STBillingRequest: IEncryptedRequest {

    var path: String {
        switch self {
        case .billingInfo:
            return "billing/info"
        case .verifi:
            return "billing/appleVerify"
        }
    }

    var bodyParams: [String : Any]? {
        switch self {
        case .billingInfo(let rand):
            return ["rand": rand]
        case .verifi(let transactions):
            let bogy = transactions.toJson()
            return bogy
        }
    }
    
}


extension STBillingRequest {
        
    struct TransactionInfo: Codable {
        let transactionIdentifier: String
        let originalTransactionIdentifier: String?
    }
    
    struct Transactions: Codable {
        let transactions: [TransactionInfo]
        let receiveData: String
    }
    
}
