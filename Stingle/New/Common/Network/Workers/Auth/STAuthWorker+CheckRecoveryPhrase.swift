//
//  STAuthWorker+CheckRecoveryPhrase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/15/21.
//

import Foundation

extension STAuthWorker {
    
    func checkRecoveryPhrase(user: STUser, phrase: String, password: String, success: @escaping Success<STEmptyResponse>, failure: @escaping Failure) {
        do {
            let key = try STMnemonic.bytes(mnemonic: phrase)
            self.checkRecoveryPhrase(user: user, password: password, privateKey: key, success: success, failure: failure)
        } catch {
            failure(STError.error(error: error))
        }
    }
    
    private func checkRecoveryPhrase(user: STUser, password: String, privateKey: [UInt8], success: @escaping Success<STEmptyResponse>, failure: @escaping Failure) {
        
        let request = STAuthRequest.checkRecoveryPhrase(email: user.email)
        let userProvider = STApplication.shared.dataBase.userProvider
        
        self.request(request: request, success: { (response: STAuth.Challenge) in
            let crypto = STApplication.shared.crypto
            guard let challengeBytes = crypto.base64ToByte(encodedStr: response.challenge) else {
                userProvider.deleteAll()
                KeyManagement.signOut()
                failure(AuthWorkerError.loginError)
                return
            }
            
            do {
                let publicKey = try crypto.getPublicKeyFromPrivateKey(byte: privateKey)
                let msgBytes = try crypto.decryptSeal(enc: challengeBytes, publicKey: publicKey, privateKey: privateKey)
                                
                guard let msg = String(bytes: msgBytes, encoding: .utf8), msg.hasPrefix("validkey_") else {
                    userProvider.deleteAll()
                    KeyManagement.signOut()
                    failure(AuthWorkerError.loginError)
                    return
                }
                try crypto.generateMainKeypair(password: password, privateKey: privateKey, publicKey: publicKey)
                KeyManagement.key = privateKey
                userProvider.update(model: user)
                KeyManagement.importServerPublicKey(pbk: response.serverPK)
                success(STEmptyResponse())
            } catch {
                failure(AuthWorkerError.loginError)
            }
                    
        }, failure: failure)
    }
    
}
