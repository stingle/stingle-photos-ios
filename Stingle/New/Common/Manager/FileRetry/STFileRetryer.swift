//
//  STFileImageRetryer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import UIKit


extension STFileRetryerManager {
    
    class Retryer<T: IDiskCacheObject> {
        
        typealias Operation = RetryOperation<T>
        
        private var myListeners = [Operation: Set<Result<T>>]()
        private var listeners: [Operation: Set<Result<T>>] {
            get {
                return self.mutableState.around {
                    return self.myListeners
                }
            } set {
                self.mutableState.around {
                    self.myListeners = newValue
                }
            }
        }
        
        
        private let operationManager = STOperationManager.shared
        private let dispatchQueue = DispatchQueue(label: "Retryer.queue.\(T.self)", attributes: .concurrent)
        fileprivate var mutableState = UnfairLock()
        
        lazy var operationQueue: ATOperationQueue = {
            let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 50, queue: self.dispatchQueue)
            return queue
        }()
        
        @discardableResult
        func retry(source: IRetrySource, success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) -> String {
            let result = Result<T>(success: success, progress: progress, failure: failure)
            self.downloadWithQueue(source: source, result: result)
            return result.identifier
        }
        
        func cancel(operation identifier: String, forceCancel: Bool = false) {
            self.mutableState.around { [weak self] in
                self?.dispatchQueue.async { [weak self] in
                    self?.cancelQueue(operation: identifier, forceCancel: forceCancel)
                }
            }
        }
        
        //MARK: - Private methods
        
        private func getrResultIDIndex(resultIdentifier: String) -> (operation: Operation, result: Result<T>)? {
            for keyValue in self.listeners {
                if let result = keyValue.value.first(where: { $0.identifier == resultIdentifier }) {
                    return (keyValue.key, result)
                }
            }
            return nil
        }
        
        func cancelQueue(operation identifier: String, forceCancel: Bool = false) {
            guard let resultID = self.getrResultIDIndex(resultIdentifier: identifier) else {
                return
            }
            self.listeners[resultID.operation]?.remove(resultID.result)
            if (self.listeners[resultID.operation] ?? []).isEmpty {
                var progress: Float = 0
                if let downloadProgress = resultID.operation.downloadProgress {
                    let total: Float = downloadProgress.totalUnitCount == 0 ? 1 : Float(downloadProgress.totalUnitCount)
                    let completed = Float(downloadProgress.completedUnitCount)
                    progress = completed / total
                }
                if forceCancel || progress < 0.2 {
                    self.listeners[resultID.operation] = nil
                    resultID.operation.cancel()
                }
            }
        }
        
        private func downloadWithQueue(source: IRetrySource, result: Result<T>) {
            self.dispatchQueue.async { [weak self] in
                self?.download(source: source, result: result)
            }
        }
        
        private func download(source: IRetrySource, result: Result<T>) {
            if let operation = self.listeners.keys.first(where: { $0.identifier == source.identifier }) {
                self.listeners[operation]?.insert(result)
            } else {
                let newOperation = self.createOperation(for: source)
                self.listeners[newOperation] = [result]
                newOperation.localWork()
                if !newOperation.isExpired {
                    self.operationManager.run(operation: newOperation, in: self.operationQueue)
                }
            }
        }
        
        private func didProgressFileQueue(source: IRetrySource, progress: Progress, operation: Operation) {
            guard let operation = self.listeners.keys.first(where: { $0.identifier == source.identifier }) else {
                return
            }
            self.listeners[operation]?.forEach({ (result) in
                result.progress(progress: progress)
            })
        }
        
        private func didDownloadQueue(source: IRetrySource, obj: T, operation: Operation) {
            guard let operation = self.listeners.keys.first(where: { $0.identifier == source.identifier }) else {
                return
            }
            self.listeners[operation]?.forEach({ (result) in
                result.success(value: obj)
            })
            self.listeners.removeValue(forKey: operation)
            
//            [operation] = nil
        }
        
        private func didFailureFileQueue(source: IRetrySource, error: IError, operation: Operation) {
            self.listeners[operation]?.forEach({ (result) in
                result.failure(error: error)
            })
            self.listeners[operation] = nil
        }
        
        //MARK: - Internal methods
        
        internal func createOperation(for source: IRetrySource) -> RetryOperation<T> {
            fatalError("method not implemented")
        }
        
        internal func didDownload(source: IRetrySource, obj: T, operation: Operation) {
            self.dispatchQueue.async { [weak self] in
                self?.didDownloadQueue(source: source, obj: obj, operation: operation)
            }
        }
        
        internal func didProgressFile(source: IRetrySource, progress: Progress, operation: Operation) {
            self.dispatchQueue.async { [weak self] in
                self?.didProgressFileQueue(source: source, progress: progress, operation: operation)
            }
        }
        
        internal func didFailureFile(source: IRetrySource, error: IError, operation: Operation) {
            self.dispatchQueue.async { [weak self] in
                self?.didFailureFileQueue(source: source, error: error, operation: operation)
            }
        }
        
    }
    
}

private protocol Lock {
    func lock()
    func unlock()
}

extension Lock {
    
    func around<T>(_ closure: () -> T) -> T {
        lock(); defer { unlock() }
        return closure()
    }
    
    func around(_ closure: () -> Void) {
        lock(); defer { unlock() }
        closure()
    }
}

extension STFileRetryerManager {
    
    final class UnfairLock: Lock {
        private let unfairLock: os_unfair_lock_t

        init() {
            unfairLock = .allocate(capacity: 1)
            unfairLock.initialize(to: os_unfair_lock())
        }

        deinit {
            unfairLock.deinitialize(count: 1)
            unfairLock.deallocate()
        }

        fileprivate func lock() {
            os_unfair_lock_lock(unfairLock)
        }

        fileprivate func unlock() {
            os_unfair_lock_unlock(unfairLock)
        }
    }
    
    class ImageRetryer: Retryer<UIImage> {
        
        private let diskCache = DiskImageCache()
        private let memoryCache = MemoryCache()
        
        override func createOperation(for source: IRetrySource) -> Operation {
            var operation: RetryOperation<UIImage>!
            operation = RetryOperation(request: source, memoryCache: self.memoryCache, diskCache: self.diskCache) { [weak self] (obj) in
                self?.didDownload(source: source, obj: obj, operation: operation)
            } progress: { [weak self] (progress) in
                self?.didProgressFile(source: source, progress: progress, operation: operation)
            } failure: { [weak self] (error) in
                self?.didFailureFile(source: source, error: error, operation: operation)
            }
            return operation
        }
        
    }
    
}
