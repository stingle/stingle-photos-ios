//
//  STSyncManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation
import UIKit

protocol ISyncManagerObserver: AnyObject {
    func syncManager(didStartSync syncManager: STSyncManager)
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?)
}

extension ISyncManagerObserver {
    func syncManager(didStartSync syncManager: STSyncManager) {}
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?) {}
}

class STSyncManager {
    
    let syncWorker = STSyncWorker()
    private var isConfigured = false
    private var dataBase: STDataBase!
    private var appLockUnlocker: STAppLockUnlocker!
    private var utils: STApplication.Utils!

    private(set) var isSyncing = false
    private let observer = STObserverEvents<ISyncManagerObserver>()
    private var isEnteredBackground = false
    
    func configure(dataBase: STDataBase, appLockUnlocker: STAppLockUnlocker, utils: STApplication.Utils) {
        guard !self.isConfigured else {
            return
        }
                
        self.isConfigured = true
        self.dataBase = dataBase
        self.appLockUnlocker = appLockUnlocker
        self.utils = utils
        
        appLockUnlocker.add(self)
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(didActivate(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(didEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.sync()
    }
    
    func sync(success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil) {
        guard self.canStartSync() else {
            failure?(SyncError.busy)
            return
        }
        self.didStartSync()
        self.utils.restoreFilesIfNeeded(reloadDB: true) { [weak self] in
            self?.syncWorker.getUpdates { [weak self] (sync) in
                self?.startDBSync(sync: sync, success: success, failure: failure)
            } failure: { [weak self] (error) in
                self?.didEndSync(error: error)
            }
        }        
    }

    //MARK: - private
    
    private func sync() {
        self.sync(success: nil, failure: nil)
    }
    
    private func canStartSync() -> Bool {
        return self.isConfigured && !self.isSyncing && UIApplication.shared.applicationState == .active && self.dataBase != nil && self.appLockUnlocker != nil && self.utils != nil && self.utils.isLogedIn() && self.appLockUnlocker.state == .unlocked
    }
    
    private func startDBSync(sync: STSync, success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil)  {
        
        self.dataBase.sync(sync) { [weak self] in
            
            success?()
            self?.didEndSync(error: nil)
            let application = STApplication.shared
            application.uploader.uploadAllLocalFiles()
            application.auotImporter.startImport()
            
        } willFinish: { info in
                        
            let gallery = info.gallery.updates.compactMap( { $0.file } )
            let albumFiles = info.albumFiles.updates.compactMap( { $0.file } )
            let deletes = info.trash.deletes.compactMap( { $0.file } )
            let trash = info.trash.updates.compactMap( { $0.file } )
            
            var deleteFileNames = [String]()
            deleteFileNames.append(contentsOf: deletes)
            deleteFileNames.append(contentsOf: gallery)
            deleteFileNames.append(contentsOf: albumFiles)
            deleteFileNames.append(contentsOf: trash)
            
            STApplication.shared.utils.deleteFiles(fileNames: deleteFileNames)

        } failure: { [weak self] error in
            failure?(error)
            self?.didEndSync(error: error)
        }
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
    
    @objc private func didActivate(_ notification: Notification) {
        if self.isEnteredBackground {
            self.sync()
        }
        self.isEnteredBackground = false
    }
    
    @objc private func didEnterBackground(_ notification: Notification) {
        self.isEnteredBackground = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension STSyncManager: IAppLockUnlockerObserver {
    
    func appLockUnlocker(didUnlockApp lockUnlocker: STAppLockUnlocker) {
        self.sync()
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
