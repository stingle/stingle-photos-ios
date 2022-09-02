//
//  STAppSettings+Backup.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/3/21.
//

import Foundation

public extension STAppSettings {
    
    struct Backup: Codable {
        
        public var isEnabled: Bool
        public var isOnlyWiFi: Bool
        public var batteryLevel: Float
        
        static public var `default`: Backup {
            let result = Backup(isEnabled: true, isOnlyWiFi: false, batteryLevel: 0.38)
            return result
        }
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.isEnabled != rhs.isEnabled || lhs.isOnlyWiFi != rhs.isOnlyWiFi || lhs.batteryLevel != rhs.batteryLevel
        }

    }
    
}
