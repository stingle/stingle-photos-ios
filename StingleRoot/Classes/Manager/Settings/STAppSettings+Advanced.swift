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
        // Auto-cache a remote video into the local encrypted store the first time it's
        // played, so re-watching is instant instead of re-streaming. On by default.
        public var autoCacheVideos: Bool

        public init(cacheSize: CacheSize, autoCacheVideos: Bool) {
            self.cacheSize = cacheSize
            self.autoCacheVideos = autoCacheVideos
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.cacheSize = try container.decode(CacheSize.self, forKey: .cacheSize)
            // Backward-compatible: installs saved before this setting existed have no
            // key — default to enabled instead of failing the whole decode (which would
            // also reset the user's `cacheSize` back to `.default`).
            self.autoCacheVideos = try container.decodeIfPresent(Bool.self, forKey: .autoCacheVideos) ?? true
        }

        public static var `default`: Advanced {
            let result = Advanced(cacheSize: .unlimited, autoCacheVideos: true)
            return result
        }

        enum CodingKeys: String, CodingKey {
            case cacheSize
            case autoCacheVideos
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
            return lhs.cacheSize != rhs.cacheSize || lhs.autoCacheVideos != rhs.autoCacheVideos
        }
    }
        
}
