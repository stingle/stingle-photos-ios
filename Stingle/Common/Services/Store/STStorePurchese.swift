//
//  STStorePurchese.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/15/21.
//

import StoreKit

extension STStore {
    
    class Purchese: NSObject {
        
        private let paymentQueue = SKPaymentQueue.default()
        private(set) var isProcessing = false
        private(set) var payment: SKPayment?
        
        private var success: Complition<SKPaymentTransaction>?
        private var failure: Complition<StoreError>?
                
        
        override init() {
            super.init()
            self.paymentQueue.add(self)
        }
                
        func buy(product: SKProduct, success: @escaping Complition<SKPaymentTransaction>, failure: @escaping Complition<StoreError>) {
            guard !self.isProcessing else {
                return
            }
            self.isProcessing = true
            let payment = SKMutablePayment(product: product)
            self.payment = payment
            
            self.success = success
            self.failure = failure
            self.paymentQueue.add(payment)
        }
        
        //MARK: - Private methods
        
        private func clean() {
            self.isProcessing = false
            self.success = nil
            self.failure = nil
        }
        
    }
    
}

extension STStore.Purchese: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        guard let transaction = transactions.first(where: { $0.payment == self.payment }) else {
            return
        }
        switch transaction.transactionState {
        case .purchased:
            self.paymentQueue.finishTransaction(transaction)
            DispatchQueue.main.async { [weak self] in
                self?.success?(transaction)
                self?.clean()
            }
        case .failed:
            self.paymentQueue.finishTransaction(transaction)
            DispatchQueue.main.async { [weak self] in
                if let error = transaction.error {
                    self?.failure?(STStore.StoreError.error(error: error))
                } else {
                    self?.failure?(STStore.StoreError.paymentFailed)
                }
                self?.clean()
            }
        default: break
        }
       
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        guard queue.transactions.first(where: { $0.payment == self.payment }) != nil else {
            return
        }
        self.failure?(STStore.StoreError.error(error: error))
        self.clean()
    }
    
}
