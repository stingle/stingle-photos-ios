//
//  STAuthWorker+CheckRecoveryPhrase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/15/21.
//

import Foundation

extension STAuthWorker {
    
    func checkRecoveryPhraseAfterLogin(user: STUser, phrase: String, password: String, success: @escaping Success<STEmptyResponse>, failure: @escaping Failure) {
        let userProvider = STApplication.shared.dataBase.userProvider
        let crypto = STApplication.shared.crypto
        self.checkRecoveryPhrase(email: user.email, phrase: phrase) { responce in
            do {
                try crypto.generateMainKeypair(password: password, privateKey: responce.privateKey, publicKey: responce.publicKey)
                KeyManagement.key = responce.privateKey
                userProvider.update(model: user)
                KeyManagement.importServerPublicKey(pbk: responce.serverPK)
                success(STEmptyResponse())
            } catch {
                userProvider.deleteAll()
                KeyManagement.signOut()
                failure(AuthWorkerError.loginError)
            }
        } failure: { error in
            userProvider.deleteAll()
            KeyManagement.signOut()
            failure(error)
        }
    }
    
    func checkRecoveryPhrase(email: String, phrase: String, success: @escaping Success<RecoveryPhraseResponse>, failure: @escaping Failure) {
        do {
            let privateKey = try STMnemonic.bytes(mnemonic: phrase)
            self.checkRecoveryPhrase(email: email, privateKey: privateKey, success: success, failure: failure)
        } catch {
            failure(STError.error(error: error))
        }
    }
    
    func recoverAccount(email: String, password: String, phraseResponse: RecoveryPhraseResponse, success: @escaping Success<STUser>, failure: @escaping Failure) {
        let crypto = STApplication.shared.crypto
        guard let serverPK = crypto.base64ToByte(encodedStr: phraseResponse.serverPK) else {
            failure(AuthWorkerError.loginError)
            return
        }
        do {
            try crypto.generateMainKeypair(password: password, privateKey: phraseResponse.privateKey, publicKey: phraseResponse.publicKey)
            let loginHash = try crypto.getPasswordHashForStorage(password: password)
            let uploadKeyBundle = try KeyManagement.getUploadKeyBundle(password: password, includePrivateKey: phraseResponse.isKeyBackedUp)
            guard let hash = loginHash["hash"], let salt = loginHash["salt"] else {
                failure(AuthWorkerError.loginError)
                return
            }
            let request = STAuthRequest.recoverAccount(email: email, loginHash: hash, newSalt: salt, uploadKeyBundle: uploadKeyBundle, serverPK: serverPK, privateKey: phraseResponse.privateKey)
            
            self.request(request: request) { [weak self] (response: STEmptyResponse) in
                self?.loginRequest(email: email, password: password, isPrivateKeyIsAlreadySaved: true, success: { user in
                    KeyManagement.importServerPublicKey(pbk: phraseResponse.serverPK)
                    success(user)
                }, failure: { error in
                    KeyManagement.signOut()
                    failure(error)
                })
            } failure: { error in
                KeyManagement.signOut()
                failure(error)
            }
        } catch {
            failure(AuthWorkerError.loginError)
            return
        }
    }
        
    //MARK: - Private methods
    
    private func checkRecoveryPhrase(email: String, privateKey: [UInt8], success: @escaping Success<RecoveryPhraseResponse>, failure: @escaping Failure) {
        let request = STAuthRequest.checkRecoveryPhrase(email: email)
        self.request(request: request, success: { (response: STAuth.Challenge) in
            let crypto = STApplication.shared.crypto
            guard let challengeBytes = crypto.base64ToByte(encodedStr: response.challenge) else {
                failure(AuthWorkerError.loginError)
                return
            }
            do {
                let isKeyBackedUp = response.isKeyBackedUp == 1
                let publicKey = try crypto.getPublicKeyFromPrivateKey(byte: privateKey)
                let msgBytes = try crypto.decryptSeal(enc: challengeBytes, publicKey: publicKey, privateKey: privateKey)
                guard let msg = String(bytes: msgBytes, encoding: .utf8), msg.hasPrefix("validkey_") else {
                    return
                }
                let result = RecoveryPhraseResponse(publicKey: publicKey,
                                                    privateKey: privateKey,
                                                    serverPK: response.serverPK,
                                                    isKeyBackedUp: isKeyBackedUp)
                success(result)
            } catch {
                failure(AuthWorkerError.loginError)
            }
        }, failure: failure)
    }
    
}

extension STAuthWorker {
    
    struct RecoveryPhraseResponse {
        let publicKey: [UInt8]
        let privateKey: [UInt8]
        let serverPK: String
        let isKeyBackedUp: Bool
    }
    
}


