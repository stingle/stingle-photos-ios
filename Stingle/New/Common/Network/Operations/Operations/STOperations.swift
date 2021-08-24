//
//  STOperations.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation

protocol INetworkOperation: Operation {
    func pause()
    func resume()
    func didStartRun(with delegate: INetworkOperationQueue)
}

class STOperation<T>: Operation, INetworkOperation {

    enum Status: String {
        case ready  = "isReady"
        case executing = "isExecuting"
        case finished = "isFinished"
        case waiting = "isWaiting"
        case canceled = "isCanceled"
    }
    
    typealias STOperationSuccess = (_ result: T) -> Void
    typealias STOperationFailure = (_ error: IError) -> Void
    typealias STOperationProgress = (_ error: Progress) -> Void
    typealias STOperationStream = (_ reciveData: Data) -> Void

    private var success: STOperationSuccess?
    private var failure: STOperationFailure?
    private var progress: STOperationProgress?
    private var stream: STOperationStream?
    
    private(set) var isRunning = false
    private(set) var isStarted = false
    private(set) var isOperationCanceled = false
    
    let uuid = UUID().uuidString
    
    var isExpired: Bool {
        return self.isCancelled || self.isOperationCanceled || self.isFinished
    }

    private(set) weak var delegate: INetworkOperationQueue?

    init(success: STOperationSuccess?, failure: STOperationFailure?) {
        self.success = success
        self.failure = failure
        self.status = .ready
        super.init()
    }

    init(success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?) {
        self.success = success
        self.progress = progress
        self.failure = failure
        self.status = .ready
        super.init()
    }
    
    init(success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?, stream: STOperationStream?) {
        self.success = success
        self.progress = progress
        self.failure = failure
        self.stream = stream
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

    private(set) var status: Status = .ready
    

    // MARK: - IBaseOperation

    override var isReady: Bool {
        return self.state == .ready
    }

    override var isExecuting: Bool {
        return self.state == .executing
    }

    override var isFinished: Bool {
        return self.state == .finished
    }
    
    override var isCancelled: Bool {
        return self.status == .canceled
    }

    override func start() {
        super.start()
        if self.isOperationCanceled {
            self.setResume()
            self.setFinished()
        } else {
            self.resume()
        }
    }

    override func cancel() {
        self.setCancel()
    }

    //MARK: - Public methods

    func finish() {
        self.setFinished()
    }

    func pause() {
        self.status = .waiting
    }

    func resume() {
        self.setResume()
    }

    func didStartRun(with delegate: INetworkOperationQueue) {
        guard !self.isRunning else {
            return
        }
        self.isRunning = true
        self.delegate = delegate
        delegate.operation(didStarted: self)
    }
    
    func didStartRunnWaitUntil(with delegate: INetworkOperationQueue) {
        guard !self.isRunning else {
            return
        }
        self.isRunning = true
        self.delegate = delegate
        delegate.operationWaitUntil(didStarted: self)
    }

    func responseSucces(result: T) {
        self.success?(result)
        self.delegate?.operation(didFinish: self, result: result)
        self.setFinished()
    }

    func responseProgress(result: Progress) {
        self.progress?(result)
    }
    
    func responseStream(result: Data) {
        self.stream?(result)
    }

    func responseFailed(error: IError) {
        self.failure?(error)
        self.delegate?.operation(didFinish: self, error: error)
        self.setFinished()
    }
    
    //MARK: - Privite
    
    private func setFinished() {
        self.success = nil
        self.failure = nil
        self.progress = nil
        self.status = .finished
        if self.isExecuting {
            self.setState(state: .finished)
        }
    }
    
    private func setResume() {
        self.status = .executing
        self.setState(state: .executing)
        if self.isOperationCanceled {
            self.setFinished()
        }
    }
    
    private func setCancel() {
        if self.isExecuting {
            self.setFinished()
        } else if self.isReady {
            self.success = nil
            self.failure = nil
            self.progress = nil
            self.status = .canceled
            self.isOperationCanceled = true
        }
        
    }
    
    private func setState(state: State) {
        guard self.state != state else {
            return
        }
        if state == .finished && !self.isExecuting {
            return
        }
        self.state = state
    }
    

}
