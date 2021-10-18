//
//  STOperationQueue.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

protocol IOperationQueue: AnyObject {
    func operation(didStarted operation: IOperation)
    func operation(didFinish operation: IOperation, result: Any)
    func operation(didFinish operation: IOperation, error: IError)
    func operationWaitUntil(didStarted operation: IOperation)
    var underlyingQueue: DispatchQueue? { get }
}

class STOperationQueue: IOperationQueue {
    
    let maxConcurrentOperationCount: Int
    let qualityOfService: QualityOfService
    
    private var operations = STObserverEvents<IOperation>()
    
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
    
    func allOperations() -> [IOperation] {
        return self.operations.objects
    }

    //MARK: - IOperationQueue
    
    func operation(didStarted operation: IOperation) {
        self.operations.addObject(operation)
        self.operationsQueue.addOperation(operation)
    }
    
    func operationWaitUntil(didStarted operation: IOperation) {
        self.operations.addObject(operation)
        self.operationsQueue.addOperations([operation], waitUntilFinished: true)
    }
    
    func operation(didFinish operation: IOperation, result: Any) {
    }
    
    func operation(didFinish operation: IOperation, error: IError) {
    }
    
}
