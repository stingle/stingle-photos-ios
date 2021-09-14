//
//  STBillingInfo.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

class STBillingInfo: Decodable {
    
    enum Plan: String, Decodable {
        case free = "free"
    }
    
    private enum CodingKeys: String, CodingKey {
        case plan = "plan"
        case expiration = "expiration"
        case paymentGw = "paymentGw"
        case isManual = "isManual"
        case spaceQuota = "spaceQuota"
        case spaceUsed = "spaceUsed"
    }
    
    let plan: Plan
    let expiration: String?
    let paymentGw: String?
    let isManual: Bool
    let spaceQuota: Int
    let spaceUsed: Int
    
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.plan = try container.decode(Plan.self, forKey: .plan)
        self.isManual = try container.decode(String.self, forKey: .isManual) == "0" ? false : true
        
        self.expiration = try container.decodeIfPresent(String.self, forKey: .expiration)
        self.paymentGw = try container.decodeIfPresent(String.self, forKey: .paymentGw)
        
        guard let spaceQuota = Int(try container.decode(String.self, forKey: .spaceQuota)), let spaceUsed = Int(try container.decode(String.self, forKey: .spaceUsed)) else {
            throw STError.unknown
        }
        
        self.spaceUsed = spaceUsed
        self.spaceQuota = spaceQuota
    }
    
}
