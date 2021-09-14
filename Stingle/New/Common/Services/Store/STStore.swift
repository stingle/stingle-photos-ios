//
//  STStore.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

class STStore {
    
    typealias Complition<T> = (_ result: T) -> Void
    
    static let store = STStore()
    
    private var productsRequests = [ProductsRequest]()
    
    private init() {}
    
    func products(by identifiers: [String], success: @escaping Complition<[Product]>, failure: @escaping Complition<StoreError>) {
        var productsRequest: ProductsRequest!
        productsRequest = ProductsRequest(productIdentifiers: identifiers) { [weak self] products in
            guard let self = self, let index = self.productsRequests.firstIndex(of: productsRequest) else {
                return
            }
            self.productsRequests.remove(at: index)
            success(products)
        } failure: { [weak self] error in
            guard let self = self, let index = self.productsRequests.firstIndex(of: productsRequest) else {
                return
            }
            self.productsRequests.remove(at: index)
            failure(error)
        }
        self.productsRequests.append(productsRequest)
    }
    
         
}

extension STStore {
    
    enum StoreError: IError {
        case error(error: Error)
        
        var message: String {
            switch self {
            case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
                return error.localizedDescription
            }
        }
    }
    
}
