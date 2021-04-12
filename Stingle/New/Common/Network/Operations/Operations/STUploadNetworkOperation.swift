//
//  STUploadNetworkOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation

class STUploadNetworkOperation<T: Decodable>: STBaseNetworkOperation<T> {
    
    typealias Result<T> = STNetworkDispatcher.Result<T>
    
    init(request: IUploadRequest, success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?) {
        super.init(request: request, success: success, failure: failure, progress: progress)
    }
    
    func startRequest() {
        
        guard let request = self.request as? IUploadRequest else {
            fatalError("request must be DownloadRequest")
        }
        
        self.dataRequest = self.networkDispatcher.upload(request: request) { [weak self] (progress) in
            self?.responseProgress(result: progress)
        } completion: { [weak self] (result: Result<T>) in
            switch result {
            case .success(let result):
                self?.responseSucces(result: result)
            case .failure(let error):
                self?.responseGetError(error: error)
            }
        }
        
    }
    
    override func resume() {
        super.resume()
        self.startRequest()
    }
    
}
