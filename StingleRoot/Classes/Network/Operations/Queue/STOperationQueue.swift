//
//  STOperationQueue.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

public protocol IOperationQueue: AnyObject {
    func operation(didStarted operation: IOperation)
    func operation(didFinish operation: IOperation, result: Any)
    func operation(didFinish operation: IOperation, error: IError)
    func operationWaitUntil(didStarted operation: IOperation)
    var underlyingQueue: DispatchQueue? { get }
}

public class STOperationQueue: IOperationQueue {
    
    let maxConcurrentOperationCount: Int
    let qualityOfService: QualityOfService
        
    weak public var underlyingQueue: DispatchQueue?
    private let operationsQueue: OperationQueue
    
    init(maxConcurrentOperationCount: Int = 5, qualityOfService: QualityOfService = .userInitiated, underlyingQueue: DispatchQueue? = nil) {
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
        self.underlyingQueue = underlyingQueue
        
        let operationsQueue = OperationQueue()
        operationsQueue.maxConcurrentOperationCount = maxConcurrentOperationCount
        operationsQueue.qualityOfService = qualityOfService
        operationsQueue.underlyingQueue = underlyingQueue
        self.operationsQueue = operationsQueue
    }
    
    
    //MARK: - Public methods
    
    func operationCount() -> Int {
        return self.operationsQueue.operationCount
    }
    
    func cancelAllOperations() {
        self.operationsQueue.cancelAllOperations()
    }
    
    func allOperations() -> [IOperation] {
        return self.operationsQueue.operations as! [IOperation]
    }

    //MARK: - IOperationQueue
    
    public func operation(didStarted operation: IOperation) {
        self.operationsQueue.addOperation(operation)
    }
    
    public func operationWaitUntil(didStarted operation: IOperation) {
        self.operationsQueue.addOperations([operation], waitUntilFinished: true)
    }
    
    public func operation(didFinish operation: IOperation, result: Any) {
    }
    
    public func operation(didFinish operation: IOperation, error: IError) {
    }
    
}
