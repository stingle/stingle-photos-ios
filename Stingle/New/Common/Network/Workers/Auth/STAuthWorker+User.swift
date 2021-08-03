//
//  STAuthWorker+User.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/29/21.
//

import Foundation

extension STAuthWorker {
    
    func removeBackcupKeys(success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        do {
            let keyBundle = try KeyManagement.getUploadKeyBundle(password: nil, includePrivateKey: false)
            self.updateBackcupKeys(keyBundle: keyBundle, success: { response in
                guard let user = STApplication.shared.user() else {
                    failure?(WorkerError.emptyData)
                    return
                }
                let newUser = STUser(email: user.email, homeFolder: user.homeFolder, isKeyBackedUp: false, token: user.token, userId: user.userId, managedObjectID: nil)
                STApplication.shared.dataBase.userProvider.update(model: newUser)
                success?(response)
            }, failure: failure)
        } catch {
            failure?(STWorker.WorkerError.error(error: error))
        }
    }
    
    func addBackcupKeys(password: String, success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        do {
            let keyBundle = try KeyManagement.getUploadKeyBundle(password: password, includePrivateKey: true)
            self.updateBackcupKeys(keyBundle: keyBundle, success: { response in
                guard let user = STApplication.shared.user() else {
                    failure?(WorkerError.emptyData)
                    return
                }
                let newUser = STUser(email: user.email, homeFolder: user.homeFolder, isKeyBackedUp: true, token: user.token, userId: user.userId, managedObjectID: nil)
                STApplication.shared.dataBase.userProvider.update(model: newUser)
                success?(response)
            }, failure: failure)
        } catch {
            failure?(STWorker.WorkerError.error(error: error))
        }
    }
    
    func resetPassword(oldPassword: String, newPassword: String, success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        
        var isReencrypt = false
        do {
            let newLoginHash = try self.crypto.getPasswordHashForStorage(password: oldPassword)
            guard let newPasswordHash = newLoginHash["hash"], let newPasswordSalt = newLoginHash["salt"] else {
                failure?(AuthWorkerError.unknown)
                return
            }
            try self.crypto.reencryptPrivateKey(oldPassword: oldPassword, newPassword: newPassword)
            isReencrypt = true
            let includePrivateKey = STApplication.shared.user()?.isKeyBackedUp ?? true
            let uploadKeyBundle = try KeyManagement.getUploadKeyBundle(password: newPassword, includePrivateKey: includePrivateKey)
            let request = STUserRequest.changePassword(keyBundle: uploadKeyBundle, newPasswordHash: newPasswordHash, newPasswordSalt: newPasswordSalt)
                                   
            self.request(request: request) { (response: STResetPassword) in
                STApplication.shared.updateAppPassword(token: response.token, password: newPassword)
                success?(STEmptyResponse())
            } failure: { error in
                try? STApplication.shared.crypto.reencryptPrivateKey(oldPassword: newPassword, newPassword: oldPassword)
                failure?(error)
            }
            
        } catch {
            failure?(WorkerError.error(error: error))
        }
        if isReencrypt {
            try? self.crypto.reencryptPrivateKey(oldPassword: newPassword, newPassword: oldPassword)
        }
        
    }
    
    func deleteAccount(password: String, success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        guard let email = STApplication.shared.user()?.email else {
            failure?(AuthWorkerError.unknown)
            return
        }
        self.preLogin(email: email, success: { [weak self] preLogin in
            self?.deleteAccount(password: password, preLogin: preLogin, success: success, failure: failure)
        }, failure: failure)
                
    }
    
    func deleteAccount(password: String, preLogin: STAuth.PreLogin, success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        
        let application = STApplication.shared
        guard let loginHash = try? application.crypto.getPasswordHashForStorage(password: password, salt: preLogin.salt) else {
            failure?(AuthWorkerError.unknown)
            return
        }
        
        let request = STUserRequest.deleteAccount(loginHash: loginHash)
        self.request(request: request, success: { (response: STEmptyResponse) in
            application.deleteAccount()
            success?(response)
        }, failure: failure)
        
    }
    
    //MARK: - Private methotd BackcupKeys
    
    private func updateBackcupKeys(keyBundle: String, success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        let request = STUserRequest.updateBackcupKeys(keyBundle: keyBundle)
        self.request(request: request, success: success, failure: failure)
    }
    
}