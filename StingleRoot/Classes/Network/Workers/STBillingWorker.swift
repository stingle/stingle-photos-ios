//
//  STBillingWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation
import StoreKit

open class STBillingWorker: STWorker {
    
    public func getBillingInfo(success: @escaping Success<STBillingInfo>, failure: Failure?) {
        guard let rand = STApplication.shared.crypto.getRandomString(length: 12) else {
            failure?(STNetworkDispatcher.NetworkError.badRequest)
            return
        }
        let request = STBillingRequest.billingInfo(rand: rand)
        self.request(request: request, success: success, failure: failure)
    }
    
    public func verifi(transactions: [SKPaymentTransaction], success: @escaping Success<STEmptyResponse>, failure: @escaping Failure) {
        var requestTransactions = [STBillingRequest.TransactionInfo]()
        
        guard let receiptData = self.getReceiptDataString() else {
            failure(WorkerError.unknown)
            return
        }
        
        for transaction in transactions {
            guard let id = transaction.transactionIdentifier else {
                failure(WorkerError.unknown)
                return
            }
            let requestTransaction = STBillingRequest.TransactionInfo(transactionIdentifier: id, originalTransactionIdentifier: transaction.original?.transactionIdentifier)
            requestTransactions.append(requestTransaction)
        }
        
        let requestBodyData = STBillingRequest.Transactions(transactions: requestTransactions, receiveData: receiptData)
        
        let request = STBillingRequest.verifi(transactions: requestBodyData)
        self.request(request: request, success: success, failure: failure)
    }
    
    
    private func getReceiptDataString() -> String? {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: [])
                return receiptString
            }
            catch {
                STLogger.log(error: error)
            }
        }
        
        return nil
    }
    
}
