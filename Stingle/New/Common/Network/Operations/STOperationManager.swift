//
//  STOperationManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

class STOperationManager {
    
    static let shared: STOperationManager = STOperationManager()
    let defaultQueue = ATOperationQueue()
    private var othersQueue = [ATOperationQueue]()
    
    private init() {}
    
    func createQueue(maxConcurrentOperationCount: Int, qualityOfService: QualityOfService = .userInteractive, queue: DispatchQueue? = nil) -> ATOperationQueue {
        let queue = ATOperationQueue(maxConcurrentOperationCount: maxConcurrentOperationCount, qualityOfService: qualityOfService, queue: queue)
        self.othersQueue.append(queue)
        return queue
    }
    
    func run(operation: INetworkOperation) {
        operation.didStartRun(with: self.defaultQueue)
    }
    
    func run(operation: INetworkOperation, in queue: ATOperationQueue) {
        operation.didStartRun(with: queue)
    }
    
}
