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
        
        private var listeners = [String: Set<Result<T>>]()
        private let operationManager = STOperationManager.shared
        private let dispatchQueue = DispatchQueue(label: "Retryer.queue.\(T.self)", attributes: .concurrent)
        private let mainQueue = DispatchQueue.main
        
        lazy var operationQueue: ATOperationQueue = {
            let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 50, queue: self.dispatchQueue)
            return queue
        }()
        
        @discardableResult
        func retry(source: IRetrySource, success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) -> String {
            let result = Result<T>(success: success, progress: progress, failure: failure)
            self.download(source: source, result: result)
            return result.identifier
        }
        
        func cancel(operation identifier: String, forceCancel: Bool = false) {
            print("downloaddownload start cancel", identifier)
            self.dispatchQueue.sync { [weak self] in
                if let resultID = self?.getrResultIDIndex(resultIdentifier: identifier) {
                    self?.listeners[resultID.operationIdentifier]?.remove(resultID.result)
                    if (self?.listeners[resultID.operationIdentifier] ?? []).isEmpty {
                        self?.listeners[resultID.operationIdentifier] = nil
                        let operation = self?.operationQueue.allOperations().first(where: { ($0 as? RetryOperation<T>)?.identifier == resultID.operationIdentifier }) as? RetryOperation<T>
                        var progress: Float = 0
                        if let downloadProgress = operation?.downloadProgress {
                            let total: Float = downloadProgress.totalUnitCount == 0 ? 1 : Float(downloadProgress.totalUnitCount)
                            let completed = Float(downloadProgress.completedUnitCount)
                            progress = completed / total
                        }
                        
                        if forceCancel || progress < 0.2 {
//                            operation?.cancel()
                            
                            print("downloaddownload cancel", identifier)
                        }
                    }
                }
            }
        }
        
        //MARK: - Private methods
        
        func getrResultIDIndex(resultIdentifier: String) -> (operationIdentifier: String, result: Result<T>)? {
            for keyValue in self.listeners {
                if let result = keyValue.value.first(where: { $0.identifier == resultIdentifier }) {
                    return (keyValue.key, result)
                }
            }
            return nil
        }
        
        //MARK: - Internal methods
        
        internal func addListener(source: IRetrySource, success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) -> Result<T> {
            let result = Result<T>(success: success, progress: progress, failure: failure)
            self.dispatchQueue.sync { [weak self] in
                if self?.listeners[source.identifier] != nil {
                    self?.listeners[source.identifier]?.insert(result)
                } else {
                    var listener = Set<Result<T>>()
                    listener.insert(result)
                    self?.listeners[source.identifier] = listener
                }
            }
            return result
        }
        
        internal func createOperation(for source: IRetrySource) -> RetryOperation<T> {
            fatalError("method not implemented")
        }
        
        internal func download(source: IRetrySource, result: Result<T>) {
            
            self.dispatchQueue.sync { [weak self] in
                
                print("downloaddownload start", result.identifier)
                
                guard let weakSelf = self else {
                    return
                }
                if weakSelf.listeners[source.identifier] != nil {
                    weakSelf.listeners[source.identifier]?.insert(result)
                } else {
                    var listener = Set<Result<T>>()
                    listener.insert(result)
                    weakSelf.listeners[source.identifier] = listener
                }
                let operation = self?.operationQueue.allOperations().first(where: { ($0 as? Operation)?.identifier == source.identifier } ) as? Operation
                
                if operation == nil || operation?.isExpired ?? true {
                    let operation = weakSelf.createOperation(for: source)
                    if !operation.isFinished {
                       
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                        
                        print("downloaddownload run", result.identifier)
                    }
                }
            }
            
        }
        
        internal func didDownload(source: IRetrySource, image: T) {
            self.mainQueue.async { [weak self] in
                self?.listeners[source.identifier]?.forEach({ (result) in
                    result.success(value: image)
                })
                self?.dispatchQueue.sync { [weak self] in
                    self?.listeners[source.identifier] = nil
                }
            }
        }
        
        internal func didProgressFile(source: IRetrySource, progress: Progress) {
            self.mainQueue.async { [weak self] in
                self?.listeners[source.identifier]?.forEach({ (result) in
                    result.progress(progress: progress)
                })
            }
        }
        
        internal func didFailureFile(source: IRetrySource, error: IError) {
            self.mainQueue.async { [weak self] in
                self?.listeners[source.identifier]?.forEach({ (result) in
                    result.failure(error: error)
                })
                self?.dispatchQueue.sync { [weak self] in
                    self?.listeners[source.identifier] = nil
                }
            }
        }
        
        
        
        
    }
    
}

extension STFileRetryerManager {
    
    class ImageRetryer: Retryer<UIImage> {
        
        private let diskCache = DiskImageCache()
        private let memoryCache = MemoryCache()
        
        override func createOperation(for source: IRetrySource) -> Operation {
            let operation = RetryOperation(request: source, memoryCache: self.memoryCache, diskCache: self.diskCache) { [weak self] (image) in
                self?.didDownload(source: source, image: image)
            } progress: { [weak self] (progress) in
                self?.didProgressFile(source: source, progress: progress)
            } failure: { [weak self] (error) in
                self?.didFailureFile(source: source, error: error)
            }
            return operation
        }
        
    }
    
}
