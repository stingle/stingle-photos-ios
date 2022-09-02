//
//  STBytesUnits.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation

public struct STBytesUnits: Equatable {
    
    public let bytes: Int64
    
    public init(bytes: Int64) {
        self.bytes = bytes
    }
    
    public init(kb: Int64) {
        self.bytes = kb * 1_024
    }
    
    public init(mb: Int64) {
        self.init(kb: mb * 1_024)
    }
    
    public init(gb: Int64) {
        self.init(mb: gb * 1_024)
    }
    
    public var kilobytes: Double {
        return Double(bytes) / 1_024
    }
    
    public var megabytes: Double {
        return kilobytes / 1_024
    }
    
    public var gigabytes: Double {
        return megabytes / 1_024
    }
    
    public var tetabytes: Double {
        return gigabytes / 1_024
    }
    
    static public var zero: STBytesUnits {
        return STBytesUnits(bytes: .zero)
    }
        
    public func getReadableUnit(format: String = ".2f") -> String {
        let format = "%" + format
        switch bytes {
        case 0..<(1_024 * 1_024):
            return "\(Int(megabytes)) mb"
        case 1_024..<(1_024 * 1_024 * 1_024):
            return "\(String(format: format, megabytes)) mb"
        case 1_024..<(1_024 * 1_024 * 1_024 * 1_024):
            return "\(String(format: format, gigabytes)) gb"
        case (1_024 * 1_024 * 1_024 * 1_024)...Int64.max:
            return "\(String(format: format, tetabytes)) tb"
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
    
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.bytes > rhs.bytes
    }
    
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        return lhs.bytes <= rhs.bytes
    }
    
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        return lhs.bytes >= rhs.bytes
    }
    
}
