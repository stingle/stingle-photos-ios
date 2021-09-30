//
//  STOperationQueue.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

protocol INetworkOperationQueue: AnyObject {
    func operation(didStarted operation: INetworkOperation)
    func operation(didFinish operation: INetworkOperation, result: Any)
    func operation(didFinish operation: INetworkOperation, error: IError)
    func operationWaitUntil(didStarted operation: INetworkOperation)
    var underlyingQueue: DispatchQueue? { get }
}

class STOperationQueue: INetworkOperationQueue {
    
    let maxConcurrentOperationCount: Int
    let qualityOfService: QualityOfService
    
    private var operations = STObserverEvents<INetworkOperation>()
    
    weak var underlyingQueue: DispatchQueue?
    
    private lazy var operationsQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = self.maxConcurrentOperationCount
        operationQueue.qualityOfService = self.qualityOfService
        operationQueue.underlyingQueue = self.underlyingQueue
        return operationQueue
    }()
    
    init(maxConcurrentOperationCount: Int = 5, qualityOfService: QualityOfService = .userInitiated, underlyingQueue: DispatchQueue? = nil) {
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
        self.underlyingQueue = underlyingQueue
    }
    
    //MARK: - Public methods
    
    func operationCount() -> Int {
        return self.operationsQueue.operationCount
    }
    
    func cancelAllOperations() {
        self.operations.forEach { operation in
            operation.cancel()
        }
    }
    
    func allOperations() -> [INetworkOperation] {
        return self.operations.objects
    }

    //MARK: - IOperationQueue
    
    func operation(didStarted operation: INetworkOperation) {
        self.operations.addObject(operation)
        self.operationsQueue.addOperation(operation)
    }
    
    func operationWaitUntil(didStarted operation: INetworkOperation) {
        self.operations.addObject(operation)
        self.operationsQueue.addOperations([operation], waitUntilFinished: true)
    }
    
    func operation(didFinish operation: INetworkOperation, result: Any) {
    }
    
    func operation(didFinish operation: INetworkOperation, error: IError) {
    }
    
}
