//
//  STFileSystem.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/17/21.
//

import Foundation

class STFileSystem {
    
    private let fileManager = FileManager.default
    private var myStoragePath: URL?

    lazy var tmpURL = self.createTmpPath()
    lazy var privateURL = self.createPrivatePath()
    
    private var cacheFolderDataSize: STBytesUnits? = nil
    private var existFilesFolderType = [FilesFolderType: URL]()

    var storageURl: URL? {
        if let myStoragePath = self.myStoragePath {
            return myStoragePath
        }
        self.myStoragePath = self.createStoragePath()
        return self.myStoragePath
    }

    var cacheOreginalsURL: URL? {
        let folder: FilesFolderType = .oreginals(type: .cache)
        if let myCachePath = self.existFilesFolderType[folder] {
            return myCachePath
        }
        if let url = self.createPath(for: folder) {
            self.existFilesFolderType[folder] = url
            return url
        }
        return nil
    }
    
    var cacheThumbsURL: URL? {
        let folder: FilesFolderType = .thumbs(type: .cache)
        if let myCachePath = self.existFilesFolderType[folder] {
            return myCachePath
        }
        if let url = self.createPath(for: folder) {
            self.existFilesFolderType[folder] = url
            return url
        }
        return nil
    }
    
    var localOreginalsURL: URL? {
        let folder: FilesFolderType = .oreginals(type: .local)
        if let myCachePath = self.existFilesFolderType[folder] {
            return myCachePath
        }
        if let url = self.createPath(for: folder) {
            self.existFilesFolderType[folder] = url
            return url
        }
        return nil
    }
    
    var localThumbsURL: URL? {
        let folder: FilesFolderType = .thumbs(type: .local)
        if let myCachePath = self.existFilesFolderType[folder] {
            return myCachePath
        }
        if let url = self.createPath(for: folder) {
            self.existFilesFolderType[folder] = url
            return url
        }
        return nil
    }
    
    func direction(for files: FilesFolderType.FolderType, create: Bool) -> URL? {
        if create {
            return self.createPath(for: files)
        }
        return self.storageURl?.appendingPathComponent(files.rawValue)
    }
    
    func direction(for files: FilesFolderType, create: Bool) -> URL? {
        if create {
            return self.createPath(for: files)
        }
        return self.storageURl?.appendingPathComponent(files.folderName)
    }
            
    func remove(file url: URL) {
        try? self.fileManager.removeItem(at: url)
    }
    
    func createDirectory(url: URL) throws {
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
        
    func move(file from: URL, to: URL) throws {
        var toPath = to
        toPath = toPath.deletingPathExtension()
        toPath = toPath.deletingLastPathComponent()
        try self.fileManager.createDirectory(at: toPath, withIntermediateDirectories: true, attributes: nil)
        try self.fileManager.moveItem(at: from, to: to)
    }
    
    func updateUrlDataSize(url: URL, size megabytes: Double) {
        guard let cacheURL = self.direction(for: .cache, create: false), url.path.contains(cacheURL.path) else {
            return
        }
        
        var cacheFolderDataSize: STBytesUnits
        if let size = self.cacheFolderDataSize {
            let newSize = self.fileManager.scanFolder(url.path).size
            cacheFolderDataSize = size + newSize
            self.cacheFolderDataSize = cacheFolderDataSize
        } else {
            cacheFolderDataSize = self.fileManager.scanFolder(cacheURL.path).size
        }
        
        guard cacheFolderDataSize.megabytes > megabytes else {
            self.cacheFolderDataSize = cacheFolderDataSize
            return
        }
        
        let scanFolder = self.fileManager.scanFolder(cacheURL.path)
        if scanFolder.size.megabytes > megabytes {
            let maxSize = megabytes / 2
            var currentSize = scanFolder.size.megabytes
            let oldDate = Date(timeIntervalSince1970: 0)
            let files = scanFolder.files.sorted { (f1, f2) -> Bool in
                return f1.dateModification ?? oldDate < f2.dateModification ?? oldDate
            }
            for file in files {
                do {
                    try self.fileManager.removeItem(atPath: file.path)
                    currentSize = currentSize - file.size.megabytes
                    if currentSize < maxSize {
                        break
                    }
                } catch {
                }
            }
            self.cacheFolderDataSize = nil
        }
    }
    
    func contents(in url: URL) -> Data? {
        return self.fileManager.contents(atPath: url.path)
    }
    
    open func fileExists(atPath path: String) -> Bool {
        return self.fileManager.fileExists(atPath: path)
    }
    
}

private extension STFileSystem {
    
    private func createStoragePath() -> URL? {
        guard let path = self.fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        guard let  home = STApplication.shared.user()?.homeFolder else {
            return nil
        }
        let homePath = "\(path)\(home)"
        guard let homePathUrl = URL(string: homePath) else {
            return nil
        }
        if self.fileManager.existence(atUrl: homePathUrl) != .directory {
            do {
                try self.fileManager.createDirectory(at: homePathUrl, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }
        return homePathUrl
    }
    
    private func createPrivatePath() -> URL? {
        guard let path = self.fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        let privatePath = "\(path)\(FolderType.private.rawValue)"
        guard let privatePathUrl = URL(string: privatePath) else {
            return nil
        }
        if self.fileManager.existence(atUrl: privatePathUrl) != .directory {
            do {
                try self.fileManager.createDirectory(at: privatePathUrl, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }
        return privatePathUrl
    }
    
    private func createTmpPath() -> URL? {
        guard let path = self.fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        let tmpPath = "\(path)\(FolderType.tmp.rawValue)"
        guard let tmpUrl = URL(string: tmpPath) else {
            return nil
        }
            
        self.remove(file: tmpUrl)
        do {
            try self.fileManager.createDirectory(at: tmpUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        return tmpUrl
    }
    
    private func createCachePath() -> URL? {
        guard let url = self.storageURl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent(FolderType.cache.rawValue)
        if self.fileManager.existence(atUrl: pathUrl) != .directory {
            do {
                try self.fileManager.createDirectory(at: pathUrl, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }
        return pathUrl
    }
    
    private func createLoalCachePath() -> URL? {
        guard let url = self.storageURl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent(FolderType.localCache.rawValue)
        if self.fileManager.existence(atUrl: pathUrl) != .directory {
            do {
                try self.fileManager.createDirectory(at: pathUrl, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }
        return pathUrl
    }
    
    private func createPath(for filesType: FilesFolderType) -> URL? {
        guard let url = self.storageURl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent(filesType.folderName)
        if self.fileManager.existence(atUrl: pathUrl) != .directory {
            do {
                try self.fileManager.createDirectory(at: pathUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return pathUrl
    }
    
    private func createPath(for type: FilesFolderType.FolderType) -> URL? {
        guard let url = self.storageURl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent(type.rawValue)
        if self.fileManager.existence(atUrl: pathUrl) != .directory {
            do {
                try self.fileManager.createDirectory(at: pathUrl, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }
        return pathUrl
    }
            
}

extension STFileSystem {
    
    enum FolderType: String {
        case storage = "storage"
        case `private` = "private"
        case tmp = "tmp"
        case cache = "Cache"
        case localCache = "LocalCache"
    }
    
    enum FilesFolderType: Equatable, Hashable {
        
        enum FolderType: String {
            case cache = "Cache"
            case local = "Local"
        }
        
        case thumbs(type: FolderType)
        case oreginals(type: FolderType)
        
        var folderName: String {
            switch self {
            case .thumbs(type: let type):
                return type.rawValue + "/Thumbs"
            case .oreginals(type: let type):
                return type.rawValue + "/Oreginals"
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.folderName == rhs.folderName
        }
        
        func hash(into hasher: inout Hasher) {
            self.folderName.hash(into: &hasher)
        }

    }
    
    func fullPath(type: FolderType, isDirectory: Bool = false) -> URL? {
        guard let fullPath = (self.storageURl?.appendingPathComponent(type.rawValue, isDirectory: isDirectory)) else {
            return nil
        }
        return fullPath
    }
    
    func folder(for type: FolderType) -> URL? {
        
        if type == .private {
            return self.privateURL
        }
                
        guard let dest = self.fullPath(type: type, isDirectory: true) else {
            return nil
        }
        if self.fileManager.existence(atUrl: dest) != .directory {
            do {
                try self.fileManager.createDirectory(at: dest, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return dest
    }
    
    func deleteFiles(files: [STLibrary.File]) {
        for file in files {
            if let oldFileThumbPath = file.fileOreginalUrl?.path {
                try? self.fileManager.removeItem(atPath: oldFileThumbPath)
            }
            
            if let fileThumbPath = file.fileThumbUrl?.path {
                try? self.fileManager.removeItem(atPath: fileThumbPath)
            }
            
        }
    }
    
    func isExistFileile(file: STLibrary.File, isThumb: Bool) -> Bool {
        guard let url = isThumb ? file.fileThumbUrl : file.fileOreginalUrl else {
            return false
        }
        return self.fileExists(atPath: url.path)
    }
    
}

extension FileManager {
    
    struct File {
        let path: String
        let size: STBytesUnits
        let dateCreation: Date?
        let dateModification: Date?
    }
    
    func existence(atUrl url: URL) -> FileExistence {
        
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        switch (exists, isDirectory.boolValue) {
        case (false, _): return .none
        case (true, false): return .file
        case (true, true): return .directory
        }
    }
    
    func subDirectories(atPath: String) -> [String]? {
        guard let subpaths = self.subpaths(atPath: atPath) else {
            return nil
        }
        var subDirs:[String] = [String]()
        for item in subpaths {
            var isDirectory: ObjCBool = false
            self.fileExists(atPath: "\(atPath)/\(item)", isDirectory: &isDirectory)
            if isDirectory.boolValue {
                subDirs.append("\(atPath)/\(item)")
            }
        }
        return subDirs
    }
    
    func subUrls(atPath: String) -> [URL]? {
        guard let subpaths = self.subpaths(atPath: atPath) else {
            return nil
        }
        var subDirs: [URL] = [URL]()
        for item in subpaths {
            guard let url = URL(string: item) else {
                continue
            }
            subDirs.append(url)
        }
        return subDirs
    }
    
    func scanFolder(_ folderPath: String) -> (size: STBytesUnits, files: [File]) {
        var folderSize: Int64 = 0
        guard let fileAttributes = try? self.attributesOfItem(atPath: folderPath), let type = fileAttributes[FileAttributeKey.type] as? FileAttributeType else {
            return (.zero, [File]())
        }
        let isHidden: Bool = (fileAttributes[FileAttributeKey.extensionHidden] as? Bool) ?? false
        if isHidden {
            return (.zero, [File]())
        }
        
        if type == .typeDirectory {
            var files = [File]()
            let subpaths = self.subpaths(atPath: folderPath) ?? []
            for path in subpaths {
                let currentPath = folderPath + "/" + path
                guard let currentFileAttributes = try? self.attributesOfItem(atPath: currentPath), let type = currentFileAttributes[FileAttributeKey.type] as? FileAttributeType else {
                    continue
                }
                let isHidden: Bool = (currentFileAttributes[FileAttributeKey.extensionHidden] as? Bool) ?? false
                guard !isHidden, type != .typeDirectory else {
                    continue
                }
                
                let currentSize = currentFileAttributes[FileAttributeKey.size] as? Int64 ?? 0
                folderSize += currentSize
                
                let dateCreation = currentFileAttributes[FileAttributeKey.creationDate] as? Date
                let dateModification = currentFileAttributes[FileAttributeKey.modificationDate] as? Date
                let file = File(path: currentPath, size: STBytesUnits(bytes: currentSize), dateCreation: dateCreation, dateModification: dateModification)
                files.append(file)
            }
            return (STBytesUnits(bytes: folderSize), files)
        } else {
            folderSize = fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
            let dateCreation = fileAttributes[FileAttributeKey.creationDate] as? Date
            let dateModification = fileAttributes[FileAttributeKey.modificationDate] as? Date
            let file = File(path: folderPath, size: STBytesUnits(bytes: folderSize), dateCreation: dateCreation, dateModification: dateModification)
            return (STBytesUnits(bytes: folderSize), [file])
        }
        
    }
    
}


