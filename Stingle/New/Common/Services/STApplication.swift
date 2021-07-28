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
    
    private lazy var myFileSystem: STFileSystem? = {
        guard let user = self.dataBase.userProvider.user else {
            fatalError("user not found")
        }
        return STFileSystem(userHomeFolderPath: user.homeFolder)
    }()
    
    let appLocker = STAppLocker()
    
    private init() {}
    
}

extension STApplication {
            
    func isLogedIn() -> Bool {
        do {
            return try STValidator().validate(user: self.dataBase.userProvider.user)
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
        self.dataBase.deleteAll()
        KeyManagement.signOut()
        STOperationManager.shared.logout()
        self.fileSystem.logOut()
        self.myFileSystem = nil
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.logOut()
        STMainVC.show()
    }
        
}
