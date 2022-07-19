//
//  STApplicationUtils.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/31/21.
//

import UIKit

public extension STApplication {
  
    class Utils {
                        
        private var application: STApplication {
            return STApplication.shared
        }
        
        func deleteFilesIfNeeded(files: [ILibraryFile], complition:(() -> Void)?) {
            DispatchQueue.global().async { [weak self] in
                guard let weakSelf = self else { return }
                let notExistFiles = weakSelf.application.dataBase.filtrNotExistFiles(files: files)
                weakSelf.application.fileSystem.deleteFiles(files: notExistFiles)
                
                if let complition = complition {
                    DispatchQueue.main.async {
                        complition()
                    }
                }
            }
        }
        
        func deleteFilesIfNeeded(fileNames: [String], complition:(() -> Void)?) {
            
            guard self.application.isFileSystemAvailable else {
                complition?()
                return
            }
            
            DispatchQueue.global().async { [weak self] in
                guard let weakSelf = self else { return }
                let notExistFiles = weakSelf.application.dataBase.filtrNotExistFileNames(fileNames: fileNames)
                weakSelf.application.fileSystem.deleteFiles(for: notExistFiles)
                if let complition = complition {
                    DispatchQueue.main.async {
                        complition()
                    }
                }
            }
        }
        
        func deleteFiles(fileNames: [String]) {
            guard self.application.isFileSystemAvailable, !fileNames.isEmpty  else {
                return
            }
            self.application.fileSystem.deleteFiles(for: fileNames)
        }
        
        func moveLocalToRemot(files: [ILibraryFile]) {
            guard self.application.isFileSystemAvailable else {
                return
            }
            self.application.fileSystem.moveLocalToRemot(files: files)
        }
        
    }
        
}

extension STApplication.Utils {
    
    func restoreFilesIfNeeded(reloadDB: Bool, complition: (() -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            guard let weakSelf = self, weakSelf.isLogedIn() else {
                complition?()
                return
            }
            let notExistFiles = weakSelf.getNotExistFiles()
            let galleryFiles = weakSelf.generateGalleryFiles(from: notExistFiles)
            weakSelf.application.dataBase.galleryProvider.add(models: galleryFiles, reloadData: reloadDB)
            complition?()
        }
    }
    
    private func generateGalleryFiles(from systemFiles: [String: (oreginal: (url: URL, date: Date?), thumb: (url: URL, date: Date?))]) -> [STLibrary.GaleryFile] {
        
        var files = [STLibrary.GaleryFile]()
        
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
            let file = STLibrary.GaleryFile(fileName: file.key, version: "1", headers: headers, dateCreated: dateCreated, dateModified: dateCreated, isRemote: false, isSynched: false, managedObjectID: nil)
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

public extension STApplication.Utils {
    
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
        guard settings.isEnabled, self.isLogedIn() else {
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

public extension STApplication.Utils  {
    
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
    
    
    func networkDispatcher(didReceive networkDispatcher: STNetworkDispatcher, logOunt: STResponse<STLogoutResponse>) {
        guard  logOunt.parts?.logout == true else {
            return
        }
        self.application.logout(appInUnauthorized: true)
    }
    
}

extension STApplication {
    
    public class var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    public class var urlTermsOfUse: URL! {
        let link = "https://stingle.org/terms/"
        return URL(string: link)!
    }
    
    public class var urlPrivacyPolicy: URL! {
        let link = "https://stingle.org/privacy/"
        return URL(string: link)!
    }

}
