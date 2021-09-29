//
//  STFileImageRetryer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import UIKit

protocol IDownloaderSource: STDownloadRequest {
    var identifier: String { get }
    var fileTmpUrl: URL { get }
    var fileSaveUrl: URL { get }
}

extension STDownloaderManager {
    
    class Downloader<T: IDiskCacheObject> {
                 
        typealias Operation = DownloaderOperation<T>
        private let operationManager = STOperationManager.shared
        let operations = STObserverEvents<Operation>()
        let dispatchQueue = DispatchQueue(label: "Retryer.queue.\(T.self)", attributes: .concurrent)
        
        lazy var operationQueue: STOperationQueue = {
            let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 20, underlyingQueue: dispatchQueue)
            return queue
        }()
        
        @discardableResult
        func download(source: IDownloaderSource, success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) -> String {
            let result = Result<T>(success: success, progress: progress, failure: failure)
            self.downloadWithQueue(source: source, result: result)
            return result.identifier
        }
        
        func cancelAllOperation() {
            self.operationQueue.cancelAllOperations()
        }
        
        func cancel(operation identifier: String, forceCancel: Bool = false) {
            self.dispatchQueue.sync { [weak self] in
                self?.cancelQueue(operation: identifier, forceCancel: forceCancel)
            }
        }
        
        //MARK: - Private methods
        
        private func operationResult(resultIdentifier: String) -> (operation: Operation, result: Result<T>)? {
            guard let operations = self.operationQueue.allOperations() as? [Operation] else {
                return nil
            }
            for operation in operations {
                guard operation.canEditResults else {
                    continue
                }
                if let result = operation.results.first(where: { $0.identifier == resultIdentifier }) {
                    return (operation, result)
                }
            }
            return nil
        }
        
        private func operation(identifier: String) -> Operation? {
            guard let operations = self.operationQueue.allOperations() as? [Operation] else {
                return nil
            }
            return operations.first(where: { $0.identifier == identifier && $0.canEditResults })
        }
        
        func cancelQueue(operation resultIdentifier: String, forceCancel: Bool = false) {
            guard let operationResult = self.operationResult(resultIdentifier: resultIdentifier), operationResult.operation.canEditResults  else {
                return
            }
            let isRemove = operationResult.operation.remove(result: operationResult.result)
            guard isRemove, operationResult.operation.results.isEmpty else {
                return
            }
            if forceCancel || operationResult.operation.progressValue < 0.2 {
                operationResult.operation.cancel()
            }
        }
        
        private func downloadWithQueue(source: IDownloaderSource, result: Result<T>) {
            self.dispatchQueue.sync { [weak self] in
                self?.download(source: source, result: result)
            }
        }
        
        private func download(source: IDownloaderSource, result: Result<T>) {
            if let operation = self.operation(identifier: source.identifier), operation.insert(result: result) {
                return
            } else {
                let newOperation = self.createOperation(for: source)
                newOperation.insert(result: result)
                if !newOperation.isExpired {
                    self.operationManager.run(operation: newOperation, in: self.operationQueue)
                }
            }
        }
        
        //MARK: - Internal methods
        
        func createOperation(for source: IDownloaderSource) -> DownloaderOperation<T> {
            fatalError("method not implemented")
        }
                
    }
    
}


