//
//  STAppSettings+Backup.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/3/21.
//

import Foundation

extension STAppSettings {
    
    struct Backup: Codable {
        
        var isEnabled: Bool
        var isOnlyWiFi: Bool
        var batteryLevel: Float
        
        static var `default`: Backup {
            let result = Backup(isEnabled: true, isOnlyWiFi: false, batteryLevel: 0.38)
            return result
        }
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.isEnabled != rhs.isEnabled || lhs.isOnlyWiFi != rhs.isOnlyWiFi || lhs.batteryLevel != rhs.batteryLevel
        }

    }
    
}
