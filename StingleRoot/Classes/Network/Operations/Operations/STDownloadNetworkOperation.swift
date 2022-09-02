//
//  STFileDownloadOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/22/21.
//

import Alamofire
import Foundation

class STDownloadNetworkOperation: STBaseNetworkOperation<URL> {
    
    var session: Alamofire.Session?
    
    init(request: IDownloadRequest, success: STOperationSuccess?, progress: STOperationProgress?, failure: STOperationFailure?) {
        super.init(request: request, success: success, failure: failure, progress: progress, stream: nil)
    }
    
    func startRequest() {
        guard let request = self.request as? IDownloadRequest else {
            fatalError("request must be DownloadRequest")
        }
        
        self.dataRequest = self.networkDispatcher.download(request: request, completion: { [weak self] (result) in
            switch result {
            case .success(let result):
                self?.responseSucces(result: result)
            case .failure(let error):
                self?.responseFailed(error: error)
            }
        }, progress: { [weak self] progress in
            self?.responseProgress(result: progress)
        })
    }
    
    override func resume() {
        super.resume()
        self.startRequest()
    }
    
}
