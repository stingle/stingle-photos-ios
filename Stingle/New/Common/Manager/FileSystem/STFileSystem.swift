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
    private var myCachePath: URL?
    
    lazy var tmpURL = self.createTmpPath()
    lazy var privateURL = self.createPrivatePath()

    var storageURl: URL? {
        if let myStoragePath = self.myStoragePath {
            return myStoragePath
        }
        self.myStoragePath = self.createStoragePath()
        return self.myStoragePath
    }
    
    var cacheURL: URL? {
        if let myCachePath = self.myCachePath {
            return myCachePath
        }
        self.myCachePath = self.createCachePath()
        return self.myCachePath
    }
            
    func subDirectories(atPath: String) -> [URL]? {
        return self.fileManager.subUrls(atPath: atPath)
    }
    
    func remove(file url: URL) {
        try? self.fileManager.removeItem(at: url)
    }
    
    func move(file from: URL, to: URL) throws {
        var toPath = to
        toPath = toPath.deletingPathExtension()
        toPath = toPath.deletingLastPathComponent()
        try self.fileManager.createDirectory(at: toPath, withIntermediateDirectories: true, attributes: nil)
        try self.fileManager.moveItem(at: from, to: to)
    }
    
    func contents(in url: URL) -> Data? {
        return self.fileManager.contents(atPath: url.path)
    }
    
}

private extension STFileSystem {
    
    func createStoragePath() -> URL? {
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
    
    func createPrivatePath() -> URL? {
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
    
    func createTmpPath() -> URL? {
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
    
    func createCachePath() -> URL? {
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
        
}

extension STFileSystem {
    
    enum FolderType: String {
        case storage = "storage"
        case `private` = "private"
        case tmp = "tmp"
        case cache = "Cache"
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
    
}

extension FileManager {
    
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
        var subDirs:[URL] = [URL]()
        for item in subpaths {
            
        }
        return subDirs
    }
    
}
