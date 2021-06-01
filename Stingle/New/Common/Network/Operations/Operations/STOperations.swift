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
    func responseSucces(result: Any)
    func responseFailed(error: IError)
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

    private var success: STOperationSuccess?
    private var failure: STOperationFailure?
    private var progress: STOperationProgress?

    private(set) var isRunning = false
    private(set) var isStarted = false
    private(set) var isRequardCanceled = false
    
    let uuid = UUID().uuidString
    
    var isExpired: Bool {
        return self.isCancelled || self.isRequardCanceled || self.isFinished
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

    override func start() {
        super.start()
        if self.status == .finished {
            self.state = .executing
            self.finish()
        } else {
            self.resume()
        }
    }

    override func cancel() {
        self.status = .canceled
        super.cancel()
        
    }

    //MARK: - Public methods

    func finish() {
        self.success = nil
        self.failure = nil
        self.progress = nil
        self.status = .finished
        if !self.isExecuting {
            self.state = .executing
        } else {
            self.state = .finished
        }
    }

    func pause() {
        self.status = .waiting
    }

    func resume() {
        self.status = .executing
        self.state = .executing
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
    

}
