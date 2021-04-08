//
//  STSyncManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation

protocol ISyncManagerObserver: class {
    func syncManager(didStartSync syncManager: STSyncManager)
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?)
}

extension ISyncManagerObserver {
    func syncManager(didStartSync syncManager: STSyncManager) {}
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?) {}
}

class STSyncManager {
    
    let syncWorker = STSyncWorker()
    let dataBase = STApplication.shared.dataBase
    
    private(set) var isSyncing = false
    private let observer = STObserverEvents<ISyncManagerObserver>()
    
    func sync(success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil) {
        guard !self.isSyncing else {
            failure?(SyncError.busy)
            return
        }
        self.didStartSync()
        self.syncWorker.getUpdates(success: { [weak self] (sync) in
            self?.startDBSync(sync: sync, success: success, failure: failure)
        }, failure: failure)
    }

    //MARK: - private
    
    private func startDBSync(sync: STSync, success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil)  {
        self.dataBase.sync(sync, finish: { error in
            if let error = error {
                failure?(error)
                self.didEndSync(error: error)
            } else {
                success?()
                self.didEndSync(error: nil)
            }
        })
    }
    
    private func didStartSync() {
        self.isSyncing = true
        self.observer.forEach { (lisner) in
            lisner.syncManager(didStartSync: self)
        }
    }
    
    private func didEndSync(error: IError?) {
        self.isSyncing = false
        self.observer.forEach { (lisner) in
            lisner.syncManager(didEndSync: self, with: error)
        }
    }
    
}

extension STSyncManager {
    
    func addListener(_ listener: ISyncManagerObserver) {
        self.observer.addObject(listener)
    }
    
    func removeListener(_ listener: ISyncManagerObserver) {
        self.observer.removeObject(listener)
    }
    
    enum SyncError: IError {
        case busy
        var message: String {
            switch self {
            case .busy:
                return "service_busy".localized
            }
        }
    }
    
}
