//
//  STStore.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import StoreKit

class STStore {
    
    typealias Complition<T> = (_ result: T) -> Void
    
    static let store = STStore()
    private var productsRequests = [ProductsRequest]()
    private let purchese = Purchese()
    
    private init() {}
    
    func products(by identifiers: [String], success: @escaping Complition<[Product]>, failure: @escaping Complition<StoreError>) {
        var productsRequest: ProductsRequest!
        productsRequest = ProductsRequest(productIdentifiers: identifiers) { [weak self] products in
            guard let self = self, let index = self.productsRequests.firstIndex(of: productsRequest) else {
                return
            }
            self.productsRequests.remove(at: index)
            
            var productsGroup = [String: Product]()
            products.forEach { product in
                productsGroup[product.productIdentifier] = product
            }
            
            var result = [Product]()
            
            identifiers.forEach { identifier in
                if let product = productsGroup[identifier] {
                    result.append(product)
                }
            }
            
            success(result)
        } failure: { [weak self] error in
            guard let self = self, let index = self.productsRequests.firstIndex(of: productsRequest) else {
                return
            }
            self.productsRequests.remove(at: index)
            failure(error)
        }
        self.productsRequests.append(productsRequest)
    }
    
    func buy(product: SKProduct, success: @escaping Complition<SKPaymentTransaction>, failure: @escaping Complition<StoreError>) {
        self.purchese.buy(product: product, success: success, failure: failure)
    }
    
    func buy(product: Product, success: @escaping Complition<SKPaymentTransaction>, failure: @escaping Complition<StoreError>) {
        self.buy(product: product.skProduct, success: success, failure: failure)
    }
    
         
}

extension STStore {
    
    enum StoreError: IError {
        case error(error: Error)
        case serviceBusy
        case paymentFailed
        
        var message: String {
            switch self {
            case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
                return error.localizedDescription
            case .serviceBusy:
                return "service_busy".localized
            case .paymentFailed:
                return "payment_failed_message".localized
            }
        }
    }
    
}
