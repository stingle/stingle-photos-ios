//
//  STStorageVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

protocol STStorageVMDelegate: AnyObject {
    
    func storageVM(didUpdateBildingInfo storageVM: STStorageVM)
    
}

class STStorageVM {
    
    enum ProductGroup: CaseIterable {
        
        case gb100
        case gb300
        case tb1
        case tb3
        case tb5
        case tb10
        case tb20
        
        struct Identifiers {
            let monthly: String
            let yearly: String
        }
        
        var identifiers: Identifiers {
            switch self {
            case .gb100:
                return Identifiers(monthly: "100gb_monthly", yearly: "100gb_yearly")
            case .gb300:
                return Identifiers(monthly: "300gb_monthly", yearly: "300gb_yearly")
            case .tb1:
                return Identifiers(monthly: "1tb_monthly", yearly: "1tb_yearly")
            case .tb3:
                return Identifiers(monthly: "3tb_monthly", yearly: "3tb_yearly")
            case .tb5:
                return Identifiers(monthly: "5tb_monthly", yearly: "5tb_yearly")
            case .tb10:
                return Identifiers(monthly: "10tb_monthly", yearly: "10tb_yearly")
            case .tb20:
                return Identifiers(monthly: "20tb_monthly", yearly: "20tb_yearly")
            }
        }
        
        
        static var allIdentifiers: [Identifiers] {
            return self.allCases.compactMap({ $0.identifiers})
        }
        
        static var allProducts: [String] {
            var result = [String]()
            self.allCases.forEach { product in
                let identifier = product.identifiers
                result.append(identifier.monthly)
                result.append(identifier.yearly)
            }
            return result
        }
        
    }
    
    weak  var delegate: STStorageVMDelegate?
    
    private let billingWorker = STBillingWorker()
    private let store = STStore.store
    
    private var products: [STStore.Product]?
    private var billingInfo: STBillingInfo?
    
    private let dbInfoProvider = STApplication.shared.dataBase.dbInfoProvider
    
    lazy var productIdentifiers: [String] = {
        return ProductGroup.allProducts
    }()
    
    init() {
        self.dbInfoProvider.add(self)
    }
    
    func getAllData(forceGet: Bool, success: @escaping (_ products: [STStore.Product], _ billingInfo: STBillingInfo) -> Void, failure: @escaping (_ error: IError) -> Void) {
        
        var myBillingInfo: STBillingInfo?
        var myProducts: [STStore.Product]?
        var hasError: Bool = false
        
        self.getBildingInfo(forceGet: forceGet) { billingInfo in
            myBillingInfo = billingInfo
            guard let products = myProducts else {
                return
            }
            success(products, billingInfo)
        } failure: { error in
            if !hasError {
                hasError = true
                failure(error)
            }
        }

        self.getProducts(forceGet: forceGet) { products in
            myProducts = products
            guard let billingInfo = myBillingInfo else {
                return
            }
            success(products, billingInfo)
        } failure: { error in
            if !hasError {
                hasError = true
                failure(error)
            }
        }        
    }
    
    func getProducts(forceGet: Bool, success: @escaping (_ result: [STStore.Product]) -> Void, failure: @escaping (_ error: IError) -> Void) {
        
        if !forceGet, let products = self.products {
            success(products)
            return
        }
        
        self.store.products(by: self.productIdentifiers) { [weak self] products in
            self?.products = products
            success(products)
        } failure: { error in
            failure(error)
        }
    }
    
    func getBildingInfo(forceGet: Bool, success: @escaping (_ result: STBillingInfo) -> Void, failure: @escaping (_ error: IError) -> Void) {
        
        if !forceGet, let billingInfo = self.billingInfo {
            success(billingInfo)
            return
        }
        
        self.billingWorker.getBillingInfo { [weak self] billingInfo in
            self?.billingInfo = billingInfo
            success(billingInfo)
        } failure: { error in
            failure(error)
        }

    }
    
        
    func getBildingInfo() -> STDBInfo {
        return self.dbInfoProvider.dbInfo
    }
    
    func buy(product identifier: String, complition: @escaping ((_ error: IError?) -> Void))  {
        
        guard let product = self.products?.first(where: { $0.productIdentifier == identifier }) else {
            complition(STError.unknown)
            return
        }
        
        self.store.buy(product: product) { transaction in
            complition(nil)
        } failure: { error in
            complition(error)
        }

    }
    
}

extension STStorageVM: IDataBaseProviderProviderObserver {
    
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        self.delegate?.storageVM(didUpdateBildingInfo: self)
    }
    
}
