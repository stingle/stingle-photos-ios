//
//  STObserverEvents.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

open class STObserverEvents<T> {

    let weakRefarray = NSPointerArray.weakObjects()
    
    public init() {}
    
    public var objects: [T] {
        return self.weakRefarray.allObjects as! [T]
    }
    
    public func addObject(_ listener: T) {
        let pointer = Unmanaged.passUnretained(listener as AnyObject).toOpaque()
        self.weakRefarray.addPointer(pointer)
    }
    
    public func removeObject(_ listener: T) {
        for (index, object) in self.objects.enumerated() {
            if (object as AnyObject) === (listener as AnyObject) {
                self.weakRefarray.removePointer(at: index)
                break
            }
        }
    }
    
    public func forEach(_ body: (T) -> Void) {
        self.objects.forEach { obj in
            body(obj)
        }
    }
    
}
