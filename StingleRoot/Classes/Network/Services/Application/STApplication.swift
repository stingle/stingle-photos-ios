//
//  STApplication.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

public class STApplication {
    
    public static let shared = STApplication()
    
    public let syncManager: STSyncManager = STSyncManager()
    public let appLockUnlocker = STAppLockUnlocker()
    public let dataBase = STDataBase()
    public let crypto = STCrypto()
    
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
    
    var isFileSystemAvailable: Bool {
        return self.dataBase.userProvider.user != nil
    }
    
    private var myFileSystem: STFileSystem?
        
    private init() {
        self.utils = Utils { [weak self] in
            self?.myFileSystem = nil
        }
        self.createFileSystem()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
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
    
}
