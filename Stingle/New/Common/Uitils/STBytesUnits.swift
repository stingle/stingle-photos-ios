//
//  STBytesUnits.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation

struct STBytesUnits: Equatable {
    
    public let bytes: Int64
    
    init(bytes: Int64) {
        self.bytes = bytes
    }
    
    init(kb: Int64) {
        self.bytes = kb * 1_024
    }
    
    init(mb: Int64) {
        self.init(kb: mb * 1_024)
    }
    
    init(gb: Int64) {
        self.init(mb: gb * 1_024)
    }
    
    var kilobytes: Double {
        return Double(bytes) / 1_024
    }
    
    var megabytes: Double {
        return kilobytes / 1_024
    }
    
    var gigabytes: Double {
        return megabytes / 1_024
    }
    
    static var zero: STBytesUnits {
        return STBytesUnits(bytes: .zero)
    }
        
    func getReadableUnit() -> String {
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
