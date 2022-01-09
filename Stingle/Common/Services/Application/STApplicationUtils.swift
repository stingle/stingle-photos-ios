//
//  STApplicationUtils.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/31/21.
//

import UIKit

extension STApplication {
  
    class Utils {
                        
        private var application: STApplication {
            return STApplication.shared
        }
        
        private var userRemoveHendler: (() -> Void)?
        
        init(userRemoveHendler: (() -> Void)?) {
            self.userRemoveHendler = userRemoveHendler
        }
        
        func deleteFilesIfNeeded(files: [STLibrary.File]) {
            let notExistFiles = self.application.dataBase.filtrNotExistFiles(files: files)
            self.application.fileSystem.deleteFiles(files: notExistFiles)
        }
        
        func deleteFilesIfNeeded(fileNames: [String]) {
            let notExistFiles = self.application.dataBase.filtrNotExistFileNames(fileNames: fileNames)
            self.application.fileSystem.deleteFiles(for: notExistFiles)
        }
        
    }
        
}

extension STApplication.Utils {
    
    func restoreFilesIfNeeded(reloadDB: Bool, complition: (() -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            guard let weakSelf = self else {
                complition?()
                return
            }
            let notExistFiles = weakSelf.getNotExistFiles()
            let galleryFiles = weakSelf.generateGalleryFiles(from: notExistFiles)
            weakSelf.application.dataBase.galleryProvider.add(models: galleryFiles, reloadData: reloadDB)
            complition?()
        }
    }
    
    private func generateGalleryFiles(from systemFiles: [String: (oreginal: (url: URL, date: Date?), thumb: (url: URL, date: Date?))]) -> [STLibrary.File] {
        
        var files = [STLibrary.File]()
        
        for file in systemFiles {
            let oreginalUrl = file.value.oreginal.url
            let thumbUrl = file.value.thumb.url
            
            guard let oreginalHeader = try? self.application.crypto.getFileHeader(url: oreginalUrl),
                  let thumbHeader = try? self.application.crypto.getFileHeader(url: thumbUrl) else {
                continue
            }
            guard let headers = try? self.application.crypto.generateEncriptedHeaders(oreginalHeader: oreginalHeader, thumbHeader: thumbHeader) else {
                continue
            }
            let dateCreated = file.value.oreginal.date ?? Date()
            guard let file = try? STLibrary.File(file: file.key, version: "1", headers: headers, dateCreated: dateCreated, dateModified: dateCreated, isRemote: false, managedObjectID: nil) else {
                continue
            }
            files.append(file)
        }
        
        return files
        
    }
    
    private func getNotExistFiles() -> [String: (oreginal: (url: URL, date: Date?), thumb: (url: URL, date: Date?))]  {
        guard let oreginalsUrl = self.application.fileSystem.url(for: .storage(type: .local(type: .oreginals))), let thumbsUrl = self.application.fileSystem.url(for: .storage(type: .local(type: .thumbs))) else {
            return [:]
        }
        var result = [String: (oreginal: (url: URL, date: Date?), thumb: (url: URL, date: Date?))]()
        let oreginalFiles = self.scanSPFiles(url: oreginalsUrl)
        let thumbFiles = self.scanSPFiles(url: thumbsUrl)
        
        for file in oreginalFiles {
            guard let thumb = thumbFiles[file.key] else {
                continue
            }
            result[file.key] = (oreginal: file.value, thumb: thumb)
        }
        
        let names: [String] = [String](result.keys)
        let notExistFileNames = self.application.dataBase.filtrNotExistFileNames(fileNames: names)
        result = result.filter({ notExistFileNames.contains($0.key) })
        return result
    }
    
    private func scanSPFiles(url: URL) -> [String: (url: URL, date: Date?)]  {
        let files = self.application.fileSystem.scanFolder(url.path).files
        var result = [String: (url: URL, date: Date?)]()
        for file in files {
            let fileUrl = URL(fileURLWithPath: file.path)
            guard fileUrl.pathExtension == "sp" else {
                continue
            }
            let name = fileUrl.lastPathComponent
            result[name] = (url: fileUrl, date: file.dateCreation)
        }
        return result
    }
    
}

extension STApplication.Utils {
    
    func isLogedIn() -> Bool {
        do {
            return try STValidator().validate(user: self.application.dataBase.userProvider.user)
        } catch  {
            return false
        }
    }
    
    func appIsLocked() -> Bool {
        return STKeyManagement.key == nil
    }
    
    func canUploadFile() -> Bool {
        let settings = STAppSettings.current.backup
        guard settings.isEnabled else {
            return false
        }
        if settings.isOnlyWiFi && STNetworkReachableService.shared.networkStatus != .wifi {
            return false
        }
        
        let level = UIDevice.current.batteryLevel
        
        #if targetEnvironment(simulator)
        return true
        #else
        if level < settings.batteryLevel {
            return false
        }
        return true
        #endif
        
    }
    
}

extension STApplication.Utils  {
    
    func user() -> STUser? {
        if self.isLogedIn() {
            return self.application.dataBase.userProvider.user
        }
        return nil
    }
    
    func updateAppPassword(token: String, password: String) {
        guard let user = self.user() else {
            return
        }
        let newUser = STUser(email: user.email, homeFolder: user.homeFolder, isKeyBackedUp: user.isKeyBackedUp, token: token, userId: user.userId, managedObjectID: nil)
        self.application.dataBase.userProvider.update(model: newUser)
        
        let key = try? STApplication.shared.crypto.getPrivateKey(password: password)
        STKeyManagement.key = key
        
        if STAppSettings.current.security.authentication.unlock {
            STBiometricAuthServices().onBiometricAuth(password: password)
        }
    }
    
    func logout() {
        self.logout(appInUnauthorized: false)
        self.application.auotImporter.logout()
    }
    
    func deleteAccount() {
        self.application.fileSystem.deleteAccount()
        self.application.dataBase.deleteAll()
        self.application.auotImporter.logout()
        STKeyManagement.signOut()
        STOperationManager.shared.logout()
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.current.logOut()
        self.userRemoveHendler?()
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
        self.application.fileSystem.logOut()
        self.application.dataBase.deleteAll()
        STKeyManagement.signOut()
        STOperationManager.shared.logout()
        STBiometricAuthServices().removeBiometricAuth()
        STAppSettings.current.logOut()
        self.userRemoveHendler?()
        STMainVC.show(appInUnauthorized: appInUnauthorized)
    }
    
}


extension STApplication {
    
    class var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    class var urlTermsOfUse: URL! {
        let link = "https://stingle.org/terms/"
        return URL(string: link)!
    }
    
    class var urlPrivacyPolicy: URL! {
        let link = "https://stingle.org/privacy/"
        return URL(string: link)!
    }
    
}
