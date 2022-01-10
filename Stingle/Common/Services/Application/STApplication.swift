//
//  STApplication.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

class STApplication {
    
    static let shared = STApplication()
    
    private(set) lazy var dataBase: STDataBase = {
        return STDataBase()
    }()
    
    private(set) lazy var crypto: STCrypto = {
        return STCrypto()
    }()
        
    private(set) lazy var downloaderManager: STDownloaderManager = {
        return STDownloaderManager()
    }()
    
    private(set) lazy var syncManager: STSyncManager = {
        return STSyncManager()
    }()
    
    private(set) lazy var uploader: STFileUploader = {
        return STFileUploader()
    }()
    
    private(set) lazy var auotImporter: STImporter.AuotImporter = {
        return STImporter.AuotImporter()
    }()
    
    private(set) var utils: Utils!
    
    var fileSystem: STFileSystem {
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
    
    private lazy var myFileSystem: STFileSystem? = {
        guard let user = self.dataBase.userProvider.user else {
            fatalError("user not found")
        }
        return STFileSystem(userHomeFolderPath: user.homeFolder)
    }()
    
    let appLocker = STAppLocker()
    
    private init() {
        self.utils = Utils { [weak self] in
            self?.myFileSystem = nil
        }
    }
    
}
