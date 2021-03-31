//
//  STBaseNetworkOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

protocol INetworkOperation: Operation {
    func pause()
    func resume()
    func didStartRun(with delegate: INetworkOperationQueue)
    func responseSucces(result: Any)
    func responseFailed(error: IError)
}

class STBaseNetworkOperation<T>: Operation, INetworkOperation {
    
    enum Status {
        case ready
        case executing
        case finished
        case waiting
        case canceled
    }
    
    typealias STOperationSuccess = (_ result: T) -> Void
    typealias STOperationFailure = (_ error: IError) -> Void
    typealias STOperationProgress = (_ error: Progress) -> Void
    
    private var success: STOperationSuccess?
    private var failure: STOperationFailure?
    private var progress: STOperationProgress?
    
    private(set) var currentProgress: Progress?
    private(set) var request: IRequest
    private(set) var isRunning = false
    private(set) var isStarted = false
    private(set) var isRequardCanceled = false
    
    let networkDispatcher = STNetworkDispatcher.sheared
    var dataRequest: NetworkTask?
    
    var isExpired: Bool {
        return self.isCancelled || self.isRequardCanceled || self.isFinished
    }
    
    
    private weak var delegate: INetworkOperationQueue?

    init(request: IRequest, success: STOperationSuccess?, failure: STOperationFailure?) {
        self.success = success
        self.failure = failure
        self.request = request
        self.status = .ready
        super.init()
    }
    
    init(request: IRequest, success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?) {
        self.success = success
        self.progress = progress
        self.failure = failure
        self.request = request
        self.status = .ready
        super.init()
    }

    // MARK: - State
    
    private enum State: String {
        case ready = "isReady"
        case executing = "isExecuting"
        case finished = "isFinished"
    }

    private var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: self.state.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: self.state.rawValue)
        }
    }
    
    private(set) var status: Status = .ready {
        didSet {
            switch self.status {
            case .ready:
                self.state = .ready
            case .executing:
                self.state = .executing
            case .finished:
                self.state = .finished
            default:
                break
            }
        }
    }
    
    // MARK: - IBaseOperation
    
    override var isReady: Bool {
        return super.isReady && self.state == .ready
    }
    
    override var isExecuting: Bool {
        return self.state == .executing
    }
    
    override var isFinished: Bool {
        return self.state == .finished
    }

    override func start() {
        super.start()
        self.isStarted = true
        if self.isRequardCanceled {
            self.status = .executing
            self.cancel()
            self.finish()
        } else {
            self.resume()
        }
    }

    override func cancel() {
        guard self.isStarted else {
            self.isRequardCanceled = true
            return
        }
        super.cancel()
        self.status = .canceled
        self.cancelDataRequest()
    }
    
    //MARK: - Public methods
    
    func finish() {
        guard !self.isFinished else {
            return
        }
        self.status = .finished
        self.success = nil
        self.failure = nil
    }
    
    func pause() {
        self.status = .waiting
        self.cancelDataRequest()
    }
    
    func resume() {
        self.status = .executing
    }
    
    func didStartRun(with delegate: INetworkOperationQueue) {
        guard !self.isRunning else {
            return
        }
        self.isRunning = true
        self.delegate = delegate
        delegate.operation(didStarted: self)
    }
    
    func responseSucces(result: Any) {
        if let result = result as? T {
            self.success?(result)
        } else {
            self.responseFailed(error: STNetworkDispatcher.NetworkError.dataNotFound)
        }
        self.finish()
    }
    
    func responseProgress(result: Progress) {
        self.progress?(result)
    }
    
    func responseFailed(error: IError) {
        self.failure?(error)
        self.finish()
    }
    
    // MARK: - Process
    
    func responseGetData(result: T) {
        self.delegate?.operation(didFinish: self, result: result)
    }
    
    func responseGetError(error: IError) {
        self.delegate?.operation(didFinish: self, error: error)
    }
    
    // MARK: - Private
    
    private func cancelDataRequest() {
        if let dataRequest = self.dataRequest {
            
            dataRequest.cancel()
                        
            self.dataRequest = nil
        } else {
            self.responseGetError(error: STNetworkDispatcher.NetworkError.cancelled)
        }
    }
    
}
