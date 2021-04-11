//
//  STUploadNetworkOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation

class STUploadNetworkOperation: STBaseNetworkOperation<Any> {
    
    init(request: IUploadRequest, success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?) {
        super.init(request: request, success: success, failure: failure, progress: progress)
    }
    
    func startRequest() {
        guard let request = self.request as? IUploadRequest else {
            fatalError("request must be DownloadRequest")
        }
        
        self.networkDispatcher.upload(request: request)
        
//        self.dataRequest = self.networkDispatcher.download(request: request, completion: { [weak self] (result) in
//            switch result {
//            case .success(let result):
//                self?.responseSucces(result: result)
//            case .failure(let error):
//                self?.responseGetError(error: error)
//                STApplication.shared.fileSystem.remove(file: url)
//            }
//        }, progress: { [weak self] progress in
//            self?.responseProgress(result: progress)
//        })
    }
    
    override func resume() {
        super.resume()
        self.startRequest()
    }
    
    
}
