//
//  Sequence+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/22/21.
//

import Foundation

extension Array {
    
    func copyMemory(toIndex: Int) -> [Element] {
        
        guard toIndex > 0 else {
            return []
        }
        
        let toIndex = Swift.min(self.count, toIndex)
        
        let arrayPointer = self.withUnsafeBufferPointer({ $0.baseAddress })
        let resultMemry = UnsafeMutablePointer<Element>.allocate(capacity: toIndex)
        memcpy(resultMemry, arrayPointer, toIndex)
        let arrary = Array(UnsafeBufferPointer(start: resultMemry, count: toIndex))
        resultMemry.deallocate()
        return arrary
    }
    
    func copyMemory(fromIndex: Int, toIndex: Int) -> [Element] {
        let dropArray = Array(self.dropFirst(Int(fromIndex)))
        return dropArray.copyMemory(toIndex: (toIndex - fromIndex))
    }
    
}
