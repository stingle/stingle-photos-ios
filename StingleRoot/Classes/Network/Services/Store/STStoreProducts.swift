//
//  STStoreProducts.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import StoreKit

extension STStore {
    
    class ProductsRequest: NSObject {
        
        private let request: SKProductsRequest
        private var success: Complition<[Product]>?
        private var failure: Complition<StoreError>?
        
                
        init(productIdentifiers: [String], success: @escaping Complition<[Product]>, failure: @escaping Complition<StoreError>) {
            self.success = success
            self.failure = failure
            
            let productIdentifiers = Set(productIdentifiers)
            self.request = SKProductsRequest(productIdentifiers: productIdentifiers)
            
            super.init()
            self.request.delegate = self
            self.request.start()
        }
        
        //MARK: - Private methods
        
        private func clean() {
            self.success = nil
            self.failure = nil
        }
    }
    
}

extension STStore.ProductsRequest: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products.compactMap { product in
            return STStore.Product(with: product)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.success?(products)
            self?.clean()
        }
        
        
        
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.failure?(STStore.StoreError.error(error: error))
            self?.clean()
        }
    }
    
}

public extension STStore {
    
    class Product {

        public let localizedDescription: String
        public let localizedTitle: String
        public let price: NSDecimalNumber
        public let priceLocale: Locale
        public let productIdentifier: String
        public let period: SubscriptionPeriod?
        
        public let skProduct: SKProduct
        
        
        public init(with product: SKProduct) {
            self.localizedDescription = product.localizedDescription
            self.localizedTitle = product.localizedTitle
            self.price = product.price
            self.priceLocale = product.priceLocale
            self.productIdentifier = product.productIdentifier
            self.period = SubscriptionPeriod(period: product.subscriptionPeriod)
            self.skProduct = product
        }
                
        public var localizedPrice: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = self.priceLocale
            return formatter.string(from: self.price)!
        }
        
        public var priceValue: Double {
            return Double(truncating: self.price)
        }
        
        public var currencyCode: String? {
            return self.priceLocale.currencyCode
        }
        
    }
    
}

public extension STStore.Product {
    
    struct SubscriptionPeriod {
        
        public enum PeriodUnit : UInt {
            case day = 0
            case week = 1
            case month = 2
            case year = 3
            
            public var localized: String {
                switch self {
                case .day:
                    return "day".localized
                case .week:
                    return "week".localized
                case .month:
                    return "month".localized
                case .year:
                    return "year".localized
                }
            }
        }
        
        public let numberOfUnits: Int
        public let periodUnit: PeriodUnit
        
        public init?(period: SKProductSubscriptionPeriod?) {
            guard let period = period, let periodUnit = PeriodUnit(rawValue: period.unit.rawValue) else {
                return nil
            }
            self.periodUnit = periodUnit
            self.numberOfUnits = period.numberOfUnits
        }
        
        
    }
    
}
