//
//  STBytesUnits.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation

public struct STBytesUnits: Equatable {
    
    public let bytes: Int64
    
    public var kilobytes: Double {
        return Double(bytes) / 1_024
    }
    
    public var megabytes: Double {
        return kilobytes / 1_024
    }
    
    public var gigabytes: Double {
        return megabytes / 1_024
    }
    
    public init(bytes: Int64) {
        self.bytes = bytes
    }
    
    static var zero: STBytesUnits {
        return STBytesUnits(bytes: .zero)
    }
        
    public func getReadableUnit() -> String {
        switch bytes {
        case 0..<1_024:
            return "\(bytes) bytes"
        case 1_024..<(1_024 * 1_024):
            return "\(String(format: "%.2f", kilobytes)) kb"
        case 1_024..<(1_024 * 1_024 * 1_024):
            return "\(String(format: "%.2f", megabytes)) mb"
        case (1_024 * 1_024 * 1_024)...Int64.max:
            return "\(String(format: "%.2f", gigabytes)) gb"
        default:
            return "\(bytes) bytes"
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.bytes == rhs.bytes
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        return Self.init(bytes: lhs.bytes + rhs.bytes)
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.bytes < rhs.bytes
    }
    
}
