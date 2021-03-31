//
//  STSyncManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation

class STSyncManager {
    
    let syncWorker = STSyncWorker()
    let dataBase = STApplication.shared.dataBase
    
    func sync(success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil) {
        self.syncWorker.getUpdates(success: { [weak self] (sync) in
            self?.startDBSync(sync: sync, success: success, failure: failure)
        }, failure: failure)
    }

    func startDBSync(sync: STSync, success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil)  {
        self.dataBase.sync(sync, finish: { error in
            if let error = error {
                failure?(error)
            } else {
                success?()
            }
        })
    }
    
    
}
