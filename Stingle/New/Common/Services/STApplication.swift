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
    
    func updateAppPassword(token: String, password: String) {
        guard let user = self.user() else {
            return
        }
        let newUser = STUser(email: user.email, homeFolder: user.homeFolder, isKeyBackedUp: user.isKeyBackedUp, token: token, userId: user.userId, managedObjectID: nil)
        self.dataBase.userProvider.update(model: newUser)
        
        let key = try? STApplication.shared.crypto.getPrivateKey(password: password)
        KeyManagement.key = key
        
        if STAppSettings.security.authentication.unlock {
            STBiometricAuthServices().onBiometricAuth(password: password)
        }
    }
    
    func logout() {
        self.logout(appInUnauthorized: false)
    }
    
    func deleteAccount() {
        self.dataBase.deleteAll()
        KeyManagement.signOut()
        STOperationManager.shared.logout()
        self.fileSystem.deleteAccount()
        self.myFileSystem = nil
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.logOut()
        STMainVC.show(appInUnauthorized: false)
    }
    
    func networkDispatcher(didReceive networkDispatcher: STNetworkDispatcher, logOunt: STResponse<STLogoutResponse>) {
        guard  logOunt.parts?.logout == true else {
            return
        }
        self.logout(appInUnauthorized: true)
    }
    
    //MARK: - private
    
    private func logout(appInUnauthorized: Bool) {
        self.dataBase.deleteAll()
        KeyManagement.signOut()
        STOperationManager.shared.logout()
        self.fileSystem.logOut()
        self.myFileSystem = nil
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.logOut()
        STMainVC.show(appInUnauthorized: appInUnauthorized)
    }
    
}
