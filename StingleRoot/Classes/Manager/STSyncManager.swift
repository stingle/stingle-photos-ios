//
//  STSyncManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/31/21.
//

import Foundation
import UIKit

public protocol ISyncManagerObserver: AnyObject {
    func syncManager(didStartSync syncManager: STSyncManager)
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?)
}

public extension ISyncManagerObserver {
    func syncManager(didStartSync syncManager: STSyncManager) {}
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?) {}
}

public class STSyncManager {
    
    let syncWorker = STSyncWorker()
    private var isConfigured = false
    private var dataBase: STDataBase!
    private var appLockUnlocker: STAppLockUnlocker!
    private var utils: STApplication.Utils!
    
    private let observer = STObserverEvents<ISyncManagerObserver>()
    private let applicationStateMonitoring = STApplicationStateMonitoring()
    private var applicationStateMonitoringID: String?
    public private(set) var isSyncing = false
    
    func configure(dataBase: STDataBase, appLockUnlocker: STAppLockUnlocker, utils: STApplication.Utils) {
        guard !self.isConfigured else {
            return
        }
        self.isConfigured = true
        self.dataBase = dataBase
        self.appLockUnlocker = appLockUnlocker
        self.utils = utils
        appLockUnlocker.add(self)
        self.addAppActivateMonitoring()
        self.sync()
    }
    
    public func sync(success: (() -> Void)? = nil, failure: ((_ error: IError) -> Void)? = nil) {
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
    
    private func addAppActivateMonitoring() {
        self.applicationStateMonitoringID = self.applicationStateMonitoring.addObserver { [weak self] state in
            guard state == .active else {
                return
            }
            self?.sync()
        }
    }
    
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
            application.autoImporter.startImport()
            
        } willFinish: { info in
            
            let galleryDelete = info.gallery.upgrade.compactMap({ $0.file })
            let albumFilesDelete = info.albumFiles.upgrade.compactMap({ $0.file  })
            let trashDelete = info.trash.upgrade.compactMap({ $0.file })

            var deleteFileNames = [String]()
            deleteFileNames.append(contentsOf: galleryDelete)
            deleteFileNames.append(contentsOf: albumFilesDelete)
            deleteFileNames.append(contentsOf: trashDelete)

            if let deletes = sync.deletes?.trashDeletes {
                deleteFileNames.append(contentsOf: deletes.compactMap({ $0.fileName }))
            }
                                    
            var moveFiles = [ILibraryFile]()
            moveFiles.append(contentsOf: Array(info.gallery.updates))
            moveFiles.append(contentsOf: Array(info.albumFiles.updates))
            moveFiles.append(contentsOf: Array(info.trash.updates))

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
    
    deinit {
        if let applicationStateMonitoringID = self.applicationStateMonitoringID {
            self.applicationStateMonitoring.removeObserver(identifier: applicationStateMonitoringID)
        }
    }
    
}

extension STSyncManager: IAppLockUnlockerObserver {
    
    public func appLockUnlocker(didUnlockApp lockUnlocker: STAppLockUnlocker) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.sync()
        }
    }
    
}

public extension STSyncManager {
    
    func addListener(_ listener: ISyncManagerObserver) {
        self.observer.addObject(listener)
    }
    
    func removeListener(_ listener: ISyncManagerObserver) {
        self.observer.removeObject(listener)
    }
    
    enum SyncError: IError {
        case busy
        public var message: String {
            switch self {
            case .busy:
                return "service_busy".localized
            }
        }
    }
    
}
