//
//  STFileSystem2.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/24/21.
//

import Foundation

class STFileSystem2 {
    
    private let fileManager = FileManager.default
    private let userHomeFolderPath: String
        
    lazy private var appUrl: URL? = {
        guard let url = self.fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        return url
    }()
   
    init(userHomeFolderPath: String) {
        self.userHomeFolderPath = userHomeFolderPath
    }
    
}

extension STFileSystem2 {
    
    func url(for type: FolderType, filePath: String) -> URL? {
        let url = self.url(for: type)?.appendingPathComponent(filePath)
        return url
    }
    
    func url(for type: FolderType) -> URL? {
        let url = self.appUrl?.appendingPathComponent(self.userHomeFolderPath).appendingPathComponent(type.stringValue)
        return url
    }
    
    func remove(folderType: FolderType) {
        guard let url = self.url(for: folderType) else {
            return
        }
        self.remove(file: url)
    }
    
}

extension STFileSystem2 {
    
    private func remove(file url: URL) {
        do {
            try self.fileManager.removeItem(at: url)
        } catch {
            print(error)
        }
    }
    
    
    
}



extension STFileSystem2 {
    
    enum FolderType {
        case storage(type: CacheType)
        case `private`
        case tmp
        
        var stringValue: String {
            switch self {
            case .storage(let type):
                return "storage/" + "\(type.stringValue)"
            case .private:
                return "private"
            case .tmp:
                return "tmp"
            }
        }
    }
    
    enum CacheType {
        
        case local(type: FileType)
        case server(type: FileType)
        
        var stringValue: String {
            switch self {
            case .local(let type):
                return "local/" + "\(type.stringValue)"
            case .server(let type):
                return "server/" + "\(type.stringValue)"
            }
        }
    }
    
    enum FileType {
        
        case thumbs
        case oreginals
        
        var stringValue: String {
            switch self {
            case .thumbs:
                return "thumbs"
            case .oreginals:
                return "oreginals"
            }
        }
    }
    
}
