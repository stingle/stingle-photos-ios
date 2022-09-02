//
//  STStreamNetworkOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/9/21.
//

import Foundation

public class STStreamNetworkOperation: STBaseNetworkOperation<(requestLength: UInt64, contentLength: UInt64, range: Range<UInt64>)> {
    
    let queue: DispatchQueue
    
    init(request: IStreamRequest, queue: DispatchQueue, success: @escaping STOperationSuccess, stream: @escaping STOperationStream, failure: @escaping STOperationFailure) {
        self.queue = queue
        super.init(request: request, success: success, failure: failure, progress: nil, stream: stream)
    }
    
    public override func resume() {
        super.resume()
        self.startStream()
    }
    
    func startStream() {
        guard let request = self.request as? IStreamRequest else {
            fatalError("request must be DownloadRequest")
        }
        
        self.dataRequest =  self.networkDispatcher.stream(request: request, queue: self.queue) { [weak self] data in
            guard !(self?.isExpired ?? true) else {
                return
            }
            self?.responseStream(result: data)
        } completion: { [weak self] result in
            guard !(self?.isExpired ?? true) else {
                return
            }
            switch result {
            case .success(let result):
                self?.responseSucces(result: result)
            case .failure(let error):
                self?.responseFailed(error: error)
            }
        }
   
    }
        
}
