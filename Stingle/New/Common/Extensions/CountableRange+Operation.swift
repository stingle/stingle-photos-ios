//
//  CountableRange+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/5/21.
//

import Foundation

extension CountableRange where Bound: SignedInteger {
    
    func contains(_ other: Self) -> Bool {
        guard !other.isEmpty else {
            return false
        }
        return contains(other.startIndex) && contains(other.endIndex - 1)
    }
    
    var middleIndex: Bound {
        guard !isEmpty else { return startIndex }
        return (endIndex - 1 - startIndex) / 2
    }
    
    func intersects(_ other: Self) -> Bool {
        guard !isEmpty, !other.isEmpty else { return false }
        if other.contains(startIndex) || other.contains(endIndex - 1) {
            return true
        }
        return contains(other.startIndex) || contains(other.endIndex - 1)
    }
}
