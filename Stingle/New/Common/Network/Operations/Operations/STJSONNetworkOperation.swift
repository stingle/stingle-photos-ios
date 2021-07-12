//
//  STNetworkOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

class STJSONNetworkOperation: STBaseNetworkOperation<Any> {
    
    override func resume() {
        super.resume()
        self.dataRequest = self.networkDispatcher.requestJSON(request: self.request) { [weak self] (result) in
            switch result {
            case .success(let result):
                self?.responseSucces(result: result)
            case .failure(let error):
                self?.responseFailed(error: error)
            }
        }
    }
    
}

class STDataNetworkOperation: STBaseNetworkOperation<Data> {
    
    override func resume() {
        super.resume()
        self.dataRequest = self.networkDispatcher.requestData(request: self.request) { [weak self] (result) in
            switch result {
            case .success(let result):
                self?.responseSucces(result: result)
            case .failure(let error):
                self?.responseFailed(error: error)
            }
        }
    }
    
}
