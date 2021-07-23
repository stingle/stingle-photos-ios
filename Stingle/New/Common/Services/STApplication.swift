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
    
    private(set) lazy var fileSystem: STFileSystem = {
        return STFileSystem()
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
    
    let appLocker = STAppLocker()
    
            
    private init() { }
    
}

extension STApplication {
            
    func isLogedIn() -> Bool {
        do {
            return try  STValidator().validate(user: self.dataBase.userProvider.user)
        } catch  {
            return false
        }
    }
    
    func appIsLocked() -> Bool {
        return KeyManagement.key == nil
    }
    
    func user() -> STUser? {
        if self.isLogedIn() {
            return self.dataBase.userProvider.user
        }
        return nil
    }
    
    func logout() {
        
    }
        
}
