//
//  STNetworkOperationDecodable.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/21/21.
//

import Foundation

class STNetworkOperationDecodable<T: Decodable>: STBaseNetworkOperation<T> {
    
    private var decoder: IDecoder?
    typealias Result<T> = STNetworkDispatcher.Result<T>
        
    init(request: IRequest, decoder: IDecoder? = nil, success: @escaping STOperationSuccess, failure: @escaping STOperationFailure) {
        super.init(request: request, success: success, failure: failure)
        self.decoder = decoder
    }
    
    override func resume() {
        super.resume()
        if let decoder = self.decoder {
            self.dataRequest = self.networkDispatcher.request(request: self.request, decoder: decoder) { [weak self] (result: Result<T>) in
                switch result {
                case .success(let result):
                    self?.responseGetData(result: result)
                case .failure(error: let error):
                    self?.responseGetError(error: error)
                }
            }
        } else {
            self.dataRequest = self.networkDispatcher.request(request: self.request) { [weak self]  (result: Result<T>) in
                switch result {
                case .success(let result):
                    self?.responseGetData(result: result)
                case .failure(error: let error):
                    self?.responseGetError(error: error)
                }
            }
        }
    }
    
}
