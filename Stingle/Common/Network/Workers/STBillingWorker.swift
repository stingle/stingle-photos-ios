//
//  STBillingWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import Foundation

class STBillingWorker: STWorker {
    
    func getBillingInfo(success: @escaping Success<STBillingInfo>, failure: Failure?) {
        guard let rand = STApplication.shared.crypto.getRandomString(length: 12) else {
            failure?(STNetworkDispatcher.NetworkError.badRequest)
            return
        }
        let request = STBillingRequest.billingInfo(rand: rand)
        self.request(request: request, success: success, failure: failure)
        
//        self.requestJSON(request: request) { json in
//            print("")
//        }
        
        
    }
    
}
