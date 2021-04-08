//
//  STUnfairLock.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/1/21.
//

import Foundation

protocol ILock {
    func lock()
    func unlock()
}

extension ILock {
    
    func around<T>(_ closure: () -> T) -> T {
        self.lock(); defer { unlock() }
        return closure()
    }
    
    func around(_ closure: () -> Void) {
        self.lock(); defer { self.unlock() }
        closure()
    }
}

final class STUnfairLock: ILock {
    
    private let unfairLock: os_unfair_lock_t

    init() {
        self.unfairLock = .allocate(capacity: 1)
        self.unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        self.unfairLock.deinitialize(count: 1)
        self.unfairLock.deallocate()
    }

    func lock() {
        os_unfair_lock_lock(self.unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(self.unfairLock)
    }
}
