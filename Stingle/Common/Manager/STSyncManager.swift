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
                        
            let galleryUpdates = info.gallery.updates.compactMap({ $0.isRemote ? $0.file : nil })
            let albumFilesUpdates = info.albumFiles.updates.compactMap({ $0.isRemote ? $0.file : nil })
            let trashUpdates = info.trash.updates.compactMap({ $0.isRemote ? $0.file : nil })

            var deleteFileNames = [String]()
            deleteFileNames.append(contentsOf: galleryUpdates)
            deleteFileNames.append(contentsOf: albumFilesUpdates)
            deleteFileNames.append(contentsOf: trashUpdates)

            if let deletes = sync.deletes?.trashDeletes {
                deleteFileNames.append(contentsOf: deletes.compactMap({ $0.fileName }))
            }

            var moveFiles = [ILibraryFile]()
            moveFiles.append(contentsOf: info.gallery.inserts.filter({ $0.isRemote }))
            moveFiles.append(contentsOf: info.albumFiles.inserts.filter({ $0.isRemote }))
            moveFiles.append(contentsOf: info.trash.inserts.filter({ $0.isRemote }))

            STApplication.shared.utils.deleteFiles(fileNames: deleteFileNames)
            STApplication.shared.utils.moveLocalToRemot(files: moveFiles)

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
