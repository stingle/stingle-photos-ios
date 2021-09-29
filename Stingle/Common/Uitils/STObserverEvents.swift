//
//  STObserverEvents.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

class STObserverEvents<T> {

    let weakRefarray = NSPointerArray.weakObjects()
    
    var objects: [T] {
        return self.weakRefarray.allObjects as! [T]
    }
    
    func addObject(_ listener: T) {
        let pointer = Unmanaged.passUnretained(listener as AnyObject).toOpaque()
        self.weakRefarray.addPointer(pointer)
    }
    
    func removeObject(_ listener: T) {
        for (index, object) in self.objects.enumerated() {
            if (object as AnyObject) === (listener as AnyObject) {
                self.weakRefarray.removePointer(at: index)
                break
            }
        }
    }
    
    func forEach(_ body: (T) -> Void) {
        self.objects.forEach { obj in
            body(obj)
        }
    }
    
}
