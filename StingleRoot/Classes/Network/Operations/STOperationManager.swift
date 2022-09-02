//
//  STOperationManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

public class STOperationManager {
    
    static public let shared: STOperationManager = STOperationManager()
    private let defaultQueue = STOperationQueue(qualityOfService: .userInteractive)
    private let uploadQueue = STOperationQueue(maxConcurrentOperationCount: 4000, qualityOfService: .background)
    private let downloadQueue = STOperationQueue(qualityOfService: .background)
    private let streamQueue = STOperationQueue(qualityOfService: .userInteractive)
   
    private var othersQueue = [STOperationQueue]()
    
    private init() {}
    
    public func createQueue(maxConcurrentOperationCount: Int, qualityOfService: QualityOfService = .userInteractive, underlyingQueue: DispatchQueue?) -> STOperationQueue {
        let queue = STOperationQueue(maxConcurrentOperationCount: maxConcurrentOperationCount, qualityOfService: qualityOfService, underlyingQueue: underlyingQueue)
        self.othersQueue.append(queue)
        return queue
    }
    
    func run(operation: IOperation) {
        operation.didStartRun(with: self.defaultQueue)
    }
    
    func runUpload(operation: IOperation) {
        operation.didStartRun(with: self.uploadQueue)
    }
    
    func runDownload(operation: IOperation) {
        operation.didStartRun(with: self.downloadQueue)
    }
    
    func runStream(operation: IOperation) {
        operation.didStartRun(with: self.streamQueue)
    }
    
    func run(operation: IOperation, in queue: STOperationQueue) {
        operation.didStartRun(with: queue)
    }
    
    func logout() {
        self.defaultQueue.cancelAllOperations()
        self.uploadQueue.cancelAllOperations()
        self.downloadQueue.cancelAllOperations()
        self.streamQueue.cancelAllOperations()
        self.othersQueue.forEach { queue in
            queue.cancelAllOperations()
        }
    }
    
}
