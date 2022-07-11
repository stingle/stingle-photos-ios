//
//  STAppSettings+Security.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/15/21.
//

import Foundation

public extension STAppSettings {
    
    struct Security: Codable {
        
        public var lockUpApp: LockUpApp
        public var authentication: BiometricAuthentication
        public var disallowScreenshots: Bool
        
        static var `default`: Security {
            let auth = BiometricAuthentication(unlock: false)
            let result = Security(lockUpApp: .minute, authentication: auth, disallowScreenshots: false)
            return result
        }
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.lockUpApp != rhs.lockUpApp || lhs.authentication != rhs.authentication || lhs.disallowScreenshots != rhs.disallowScreenshots
        }
        
    }
    
}

public extension STAppSettings.Security {
    
    enum LockUpApp: String, CaseIterable, StringPointer, Codable {
        
        case immediately = "immediately"
        case seconds10 = "seconds10"
        case seconds30 = "seconds30"
        case minute = "minute"
        case minutes5 = "minutes5"
        case minutes10 = "minutes10"
        case minutes30 = "minutes30"
        case hour = "hour"
        
        public var stringValue: String {
            switch self {
            case .immediately:
                return "immediately".localized
            case .seconds10:
                return String(format: "seconds_count".localized, "\(10)")
            case .seconds30:
                return String(format: "seconds_count".localized, "\(30)")
            case .minute:
                return "minute".localized
            case .minutes5:
                return String(format: "minutes_count".localized, "\(5)")
            case .minutes10:
                return String(format: "minutes_count".localized, "\(10)")
            case .minutes30:
                return String(format: "minutes_count".localized, "\(30)")
            case .hour:
                return "hour".localized
            }
        }
        
        public var timeInterval: TimeInterval {
            switch self {
            case .immediately:
                return .zero
            case .seconds10:
                return 10
            case .seconds30:
                return 30
            case .minute:
                return 60
            case .minutes5:
                return 5 * 60
            case .minutes10:
                return 10 * 60
            case .minutes30:
                return 30 * 60
            case .hour:
                return 60 * 60
            }
        }
    }
    
    struct BiometricAuthentication: Codable {
        public var unlock: Bool
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.unlock != rhs.unlock
        }
    }
    
}
