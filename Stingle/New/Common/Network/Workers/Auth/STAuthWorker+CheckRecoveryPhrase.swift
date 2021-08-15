//
//  STAuthWorker+CheckRecoveryPhrase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/15/21.
//

import Foundation

extension STAuthWorker {
    
    func checkRecoveryPhrase(user: STUser, phrase: String, success: Success<STEmptyResponse>, failure: @escaping Failure) {
        do {
            let key = try STMnemonic.bytes(mnemonic: phrase)
            self.checkRecoveryPhrase(user: user, key: key, success: success, failure: failure)
        } catch {
            failure(STError.error(error: error))
        }
    }
    
    private func checkRecoveryPhrase(user: STUser, key: [UInt8], success: Success<STEmptyResponse>, failure: @escaping Failure) {
        
        let request = STAuthRequest.checkRecoveryPhrase(email: user.email)
        
        self.request(request: request, success: { (response: STAuth.Challenge) in
            
            print("")
            
            
        }, failure: failure)
        

    }
    
}
