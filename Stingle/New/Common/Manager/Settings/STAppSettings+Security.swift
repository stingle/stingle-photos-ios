//
//  STAppSettings+Security.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/15/21.
//

import Foundation

extension STAppSettings {
    
    struct Security: Codable {
        
        var lockUpApp: LockUpApp
        var authentication: BiometricAuthentication
        var disallowScreenshots: Bool
        
        static var `default`: Security {
            let auth = BiometricAuthentication(touchID: true, requireConfirmation: false)
            let result = Security(lockUpApp: .minute, authentication: auth, disallowScreenshots: false)
            return result
        }
    }
    
}

extension STAppSettings.Security {
    
    enum LockUpApp: String, CaseIterable, StringPointer, Codable {
        
        case immediately = "immediately"
        case seconds10 = "seconds10"
        case seconds30 = "seconds30"
        case minute = "minute"
        case minutes5 = "minutes5"
        case minutes10 = "minutes10"
        case minutes30 = "minutes30"
        case hour = "hour"
        
        var stringValue: String {
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
    }
    
    struct BiometricAuthentication: Codable {
        var touchID: Bool
        var requireConfirmation: Bool
    }
    
}
