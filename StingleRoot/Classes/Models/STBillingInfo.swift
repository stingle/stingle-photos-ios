//
//  STBillingInfo.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

public class STBillingInfo: Decodable {
    
    public enum Plan {
        
        case free
        case product(id: String)
        
        public var identifier: String {
            switch self {
            case .free:
                return "free"
            case .product(let id):
                return id
            }
        }
        
        static func == (lhs: Plan, rhs: Plan) -> Bool {
            lhs.identifier == rhs.identifier
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case plan = "plan"
        case expiration = "expiration"
        case paymentGw = "paymentGw"
        case isManual = "isManual"
        case spaceQuota = "spaceQuota"
        case spaceUsed = "spaceUsed"
    }
    
    public let plan: Plan
    public let expiration: String?
    public let paymentGw: String?
    public let isManual: Bool
    public let spaceQuota: Double
    public let spaceUsed: Double
    
    required public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let spaceQuota = Double(try container.decode(String.self, forKey: .spaceQuota)), let spaceUsed = Double(try container.decode(String.self, forKey: .spaceUsed)) else {
            throw STError.unknown
        }
        
        self.isManual = try container.decode(String.self, forKey: .isManual) == "0" ? false : true
        
        self.expiration = try container.decodeIfPresent(String.self, forKey: .expiration)
        self.paymentGw = try container.decodeIfPresent(String.self, forKey: .paymentGw)
        
        let plan = try container.decode(String.self, forKey: .plan)
        
        if plan == "free" {
            self.plan = .free
        } else {
            self.plan = .product(id: plan)
        }
        
        self.spaceUsed = spaceUsed
        self.spaceQuota = spaceQuota
    }
    
    public init(plan: Plan, expiration: String?, paymentGw: String?, isManual: Bool, spaceQuota: Double, spaceUsed: Double) {
        self.plan = plan
        self.expiration = expiration
        self.isManual = isManual
        self.spaceQuota = spaceQuota
        self.spaceUsed = spaceUsed
        self.paymentGw = paymentGw
    }
    
}
