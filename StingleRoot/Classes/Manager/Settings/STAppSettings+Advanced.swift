//
//  STAppSettings+Advanced.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/8/21.
//

import Foundation

extension STAppSettings {
    
    public struct Advanced: Codable {
        
        public var cacheSize: CacheSize
        
        public static var `default`: Advanced {
            let result = Advanced(cacheSize: .unlimited)
            return result
        }
        
        public enum CacheSize: String, Codable, CaseIterable {
           
            case unlimited = "unlimited"
            case gb5 = "gb5"
            case gb20 = "gb20"
            case gb50 = "gb50"
            
            public var bytesUnits: STBytesUnits {
                switch self {
                case .unlimited:
                    return STBytesUnits(gb: 1024)
                case .gb5:
                    return STBytesUnits(gb: 5)
                case .gb20:
                    return STBytesUnits(gb: 20)
                case .gb50:
                    return STBytesUnits(gb: 50)
                }
            }
            
            public var localized: String {
                switch self {
                case .unlimited:
                    return "unlimited".localized
                default:
                    return bytesUnits.getReadableUnit(format: ".0f").uppercased()
                }
            }
        }
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.cacheSize != rhs.cacheSize
        }
    }
        
}
