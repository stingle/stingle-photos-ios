//
//  STBaseNetworkOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

public class STBaseNetworkOperation<T>: STOperation<T> {

    private(set) var currentProgress: Progress?
    private(set) var request: IRequest
    
    let networkDispatcher = STNetworkDispatcher.sheared
    var dataRequest: INetworkTask?
    
    init(request: IRequest, success: STOperationSuccess?, failure: STOperationFailure?) {
        self.request = request
        super.init(success: success, failure: failure, progress: nil)
    }
    
    init(request: IRequest, success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?, stream: STOperationStream?) {
        self.request = request
        super.init(success: success, failure: failure, progress: progress, stream: stream)
    }
    
    // MARK: - IBaseOperation

    public override func cancel() {
        super.cancel()
        self.cancelDataRequest()
    }
    
    //MARK: - Public methods
    
    public override func pause() {
        super.pause()
        self.cancelDataRequest()
    }

    // MARK: - Private
    
    private func cancelDataRequest() {
        if let dataRequest = self.dataRequest {
            dataRequest.cancel()
        } else {
            self.responseFailed(error: STNetworkDispatcher.NetworkError.cancelled)
        }
    }
    
}
