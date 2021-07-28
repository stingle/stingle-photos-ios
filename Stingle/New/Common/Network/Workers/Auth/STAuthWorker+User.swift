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
            let keyBundle = try KeyManagement.getUploadKeyBundle(password: password, includePrivateKey: false)
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
    
    //MARK: - Private methotd BackcupKeys
    
    private func updateBackcupKeys(keyBundle: String, success: Success<STEmptyResponse>? = nil, failure: Failure? = nil) {
        let request = STUserRequest.updateBackcupKeys(keyBundle: keyBundle)
        self.request(request: request, success: success, failure: failure)
    }
    
}
