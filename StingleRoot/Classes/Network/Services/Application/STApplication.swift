//
//  STApplication.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

public protocol STApplicationDelegate: AnyObject {
    func application(appDidLogouted app: STApplication, appInUnauthorized: Bool)
    func application(appDidDeleteAccount app: STApplication)
    func application(appDidLoced app: STApplication, isAutoLock: Bool)
}

public class STApplication {
    
    static fileprivate var appIsConfigureed = false
    public static let shared = STApplication()
    
    public let syncManager: STSyncManager = STSyncManager()
    public let appLockUnlocker: STAppLockUnlocker
    public let dataBase = STDataBase()
    public let crypto = STCrypto()
    public weak var delegate: STApplicationDelegate?
    
    public private(set) var utils: Utils!
    
    public private(set) lazy var downloaderManager: STDownloaderManager = {
        return STDownloaderManager()
    }()
        
    public private(set) lazy var uploader: STFileUploader = {
        return STFileUploader()
    }()
    
    public private(set) lazy var autoImporter: STImporter.AutoImporter = {
        return STImporter.AutoImporter()
    }()
        
    public var fileSystem: STFileSystem {
        guard let user = self.dataBase.userProvider.user else {
            fatalError("user not found")
        }
        if let myFileSystem = self.myFileSystem {
            return myFileSystem
        }
        let result = STFileSystem(userHomeFolderPath: user.homeFolder)
        self.myFileSystem = result
        return result
    }
    
    public var isFileSystemAvailable: Bool {
        return self.dataBase.userProvider.user != nil
    }
    
    private var myFileSystem: STFileSystem?
        
    private init() {
        self.utils = Utils()
        self.appLockUnlocker = STAppLockUnlocker(callBackLock: { appIsLocked, isAutoLock  in
            STApplication.shared.appDidLocked(appIsLocked: appIsLocked, isAutoLock: isAutoLock)
        })
        self.createFileSystem()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.syncManager.configure(dataBase: weakSelf.dataBase, appLockUnlocker: weakSelf.appLockUnlocker, utils: weakSelf.utils)
        }
    }
    
    private func createFileSystem() {
        guard self.myFileSystem == nil, let user = self.dataBase.userProvider.user else {
            return
        }
        self.myFileSystem = STFileSystem(userHomeFolderPath: user.homeFolder)
    }
    
    private func appDidLocked(appIsLocked: Bool, isAutoLock: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            if !appIsLocked {
                weakSelf.syncManager.sync()
                weakSelf.dataBase.reloadData()
            } else {
                weakSelf.delegate?.application(appDidLoced: weakSelf, isAutoLock: isAutoLock)
            }
        }
    }
}

public extension STApplication {
    
    func configure(end: @escaping (() -> Void)) {
        DispatchQueue.global().async { [weak self] in
            guard !STApplication.appIsConfigureed else {
                end()
                return
            }
            self?.myFileSystem?.migrate()
            STAppSettings.migrate()
            STApplication.appIsConfigureed = true
            DispatchQueue.main.async {
                end()
            }
        }
    }
    
    func logout(appInUnauthorized: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.logoutCashe()
            weakSelf.delegate?.application(appDidLogouted: weakSelf, appInUnauthorized: appInUnauthorized)
        }
        
    }
    
    func deleteAccount() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.deleteAccountCashe()
            weakSelf.delegate?.application(appDidDeleteAccount: weakSelf)
        }
    }
    
}

fileprivate extension STApplication {
    
    func deleteAccountCashe() {
        STOperationManager.shared.logout()
        self.myFileSystem?.deleteAccount()
        self.dataBase.deleteAll()
        self.autoImporter.logout()
        STKeyManagement.signOut()
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.current.logOut()
        self.myFileSystem = nil
    }
    
    func logoutCashe() {
        STOperationManager.shared.logout()
        self.autoImporter.logout()
        self.myFileSystem?.logOut()
        self.dataBase.deleteAll()
        STKeyManagement.signOut()
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.current.logOut()
        self.myFileSystem = nil
    }
    
}
