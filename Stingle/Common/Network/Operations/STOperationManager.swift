//
//  STOperationManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

class STOperationManager {
    
    static let shared: STOperationManager = STOperationManager()
    let defaultQueue = STOperationQueue(qualityOfService: .userInteractive)
    let uploadQueue = STOperationQueue(qualityOfService: .background)
    let downloadQueue = STOperationQueue(qualityOfService: .background)
   
    private var othersQueue = [STOperationQueue]()
    
    private init() {}
    
    func createQueue(maxConcurrentOperationCount: Int, qualityOfService: QualityOfService = .userInteractive, underlyingQueue: DispatchQueue?) -> STOperationQueue {
        let queue = STOperationQueue(maxConcurrentOperationCount: maxConcurrentOperationCount, qualityOfService: qualityOfService, underlyingQueue: underlyingQueue)
        self.othersQueue.append(queue)
        return queue
    }
    
    func run(operation: INetworkOperation) {
        operation.didStartRun(with: self.defaultQueue)
    }
    
    func runUpload(operation: INetworkOperation) {
        operation.didStartRun(with: self.uploadQueue)
    }
    
    func runDownload(operation: INetworkOperation) {
        operation.didStartRun(with: self.downloadQueue)
    }
    
    func run(operation: INetworkOperation, in queue: STOperationQueue) {
        operation.didStartRun(with: queue)
    }
    
    func logout() {
        self.defaultQueue.cancelAllOperations()
        self.uploadQueue.cancelAllOperations()
        self.downloadQueue.cancelAllOperations()
    }
    
}
