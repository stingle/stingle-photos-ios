//
//  STFileSystem2.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/24/21.
//

import Foundation

class STFileSystem {
    
    private let fileManager = FileManager.default
    private let userHomeFolderPath: String
    
    private var cacheFolderDataSize: STBytesUnits? = nil
        
    lazy private var appUrl: URL? = {
        guard let url = self.fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        return url
    }()
   
    init(userHomeFolderPath: String) {
        self.userHomeFolderPath = userHomeFolderPath
        self.creatAllPath()
        #if DEBUG
        print("user folder", self.appUrl?.path ?? "")
        #endif
    }
    
    func logOut() {
        guard let cacheUrl = self.url(for: .storage(type: .server(type: nil))), let privateKeyUrl = STFileSystem.privateKeyUrl() else {
            return
        }
        self.remove(file: cacheUrl)
        self.remove(file: privateKeyUrl)
    }
    
    func deleteAccount() {
        guard let userUrl = self.appUrl?.appendingPathComponent(self.userHomeFolderPath), let privateKeyUrl = STFileSystem.privateKeyUrl() else {
            return
        }
        self.remove(file: userUrl)
        self.remove(file: privateKeyUrl)
    }
    
    func removeCache() {            
        guard let oreginals = self.url(for: .storage(type: .server(type: .oreginals))), let thumbs = self.url(for: .storage(type: .server(type: .thumbs))) else {
            return
        }
        self.remove(file: oreginals)
        self.remove(file: thumbs)
    }
    
    func freeUpSpace() {
        guard let oreginals = self.url(for: .storage(type: .server(type: .oreginals))) else {
            return
        }
        self.remove(file: oreginals)
    }
        
    private func creatAllPath() {
        FolderType.allCases.forEach { type in
            if let url = self.url(for: type) {
                switch type {
                case .tmp:
                    self.remove(file: url)
                default:
                    break
                }
                try? self.createDirectory(url: url)
            }
        }
       self.fileManager.clearTmpDirectory()
    }
    
}

extension STFileSystem {
    
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
    
    class func url(for type: FolderType, userHomeFolderPath: String) -> URL? {
        
        let fileManager = FileManager.default
        
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        
        let url = cachesDirectory.appendingPathComponent(userHomeFolderPath).appendingPathComponent(type.stringValue)
        
        return url
    }
    
    class func remove(userHomeFolderPath: String) {
        guard let cacheUrl = self.url(for: .storage(type: .server(type: nil)), userHomeFolderPath: userHomeFolderPath), let privateKeyUrl = STFileSystem.privateKeyUrl() else {
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: cacheUrl.path) {
            try? fileManager.removeItem(at: cacheUrl)
        }
        
        if fileManager.fileExists(atPath: privateKeyUrl.path) {
            try? fileManager.removeItem(at: privateKeyUrl)
        }

    }
        
}

extension STFileSystem {
    
    var localThumbsURL: URL? {
        return self.url(for: .storage(type: .local(type: .thumbs)))
    }
    
    var localOreginalsURL: URL? {
        return self.url(for: .storage(type: .local(type: .oreginals)))
    }
    
    func url(for file: File) -> URL? {
        let url = self.url(for: file.type, filePath: file.fileName)
        return url
    }
   
    func remove(file: File) {
        guard let url = self.url(for: file) else {
            return
        }
        self.remove(file: url)
    }
    
    func move(file from: File, to: File) throws {
        guard let fromUrl = self.url(for: from), let toUrl = self.url(for: to)  else {
            throw FileSystemError.incorrectUrl
        }
        try self.move(file: fromUrl, to: toUrl)
    }
    
    func scanFolder(_ folderPath: String) -> (size: STBytesUnits, files: [FileManager.File]) {
        return self.fileManager.scanFolder(folderPath)
    }
                
}

extension STFileSystem {
    
    func fileThumbUrl(fileName: String, isRemote: Bool) -> URL? {
        let url = isRemote ? self.url(for: .storage(type: .server(type: .thumbs)), filePath: fileName) : self.url(for: .storage(type: .local(type: .thumbs)), filePath: fileName)
        return url
    }
    
    func fileOreginalUrl(fileName: String, isRemote: Bool) -> URL? {
        let url = isRemote ? self.url(for: .storage(type: .server(type: .oreginals)), filePath: fileName) : self.url(for: .storage(type: .local(type: .oreginals)), filePath: fileName)
        return url
    }
    
    func deleteAllData(for fileName: String) {
        
        if let fileThumbUrl = self.fileThumbUrl(fileName: fileName, isRemote: true) {
            self.remove(file: fileThumbUrl)
        }
        
        if let fileThumbUrl = self.fileThumbUrl(fileName: fileName, isRemote: false) {
            self.remove(file: fileThumbUrl)
        }
        
        if let fileOreginalUrl = self.fileOreginalUrl(fileName: fileName, isRemote: true) {
            self.remove(file: fileOreginalUrl)
        }
        
        if let fileOreginalUrl = self.fileOreginalUrl(fileName: fileName, isRemote: false) {
            self.remove(file: fileOreginalUrl)
        }
        
    }
    
    func deleteFiles(for fileNames: Set<String>, in cacheType: CacheType) {
        
        let folder = FolderType.storage(type: cacheType)
        guard !fileNames.isEmpty, let url = self.url(for: folder), let subpathsArray = self.fileManager.subpaths(atPath: url.path), !subpathsArray.isEmpty else {
            return
        }
                
        let subpaths = Set(subpathsArray)
        let intersection = fileNames.intersection(subpaths)
        
        intersection.forEach { name in
            let url = url.appendingPathComponent(name)
            self.remove(file: url)
        }

    }
    
    func deleteFiles(for fileNames: [String]) {
        let fileNames = Set(fileNames)
        let localOreginalsType = CacheType.local(type: .oreginals)
        let localThumbsType = CacheType.local(type: .thumbs)
        let serverOreginalsType = CacheType.server(type: .oreginals)
        let serverThumbsType = CacheType.server(type: .thumbs)
        
        self.deleteFiles(for: fileNames, in: localOreginalsType)
        self.deleteFiles(for: fileNames, in: localThumbsType)
        self.deleteFiles(for: fileNames, in: serverOreginalsType)
        self.deleteFiles(for: fileNames, in: serverThumbsType)
    }
    
    func moveLocalToRemot(file: ILibraryFile) {
        if let local = self.fileThumbUrl(fileName: file.file, isRemote: false), let server = self.fileThumbUrl(fileName: file.file, isRemote: true) {
            try? self.move(file: local, to: server)
        }
        if let local = self.fileOreginalUrl(fileName: file.file, isRemote: false), let server = self.fileOreginalUrl(fileName: file.file, isRemote: true) {
            try? self.move(file: local, to: server)
        }
    }
    
    func moveLocalToRemot(files: [ILibraryFile]) {
        files.forEach { file in
            self.moveLocalToRemot(file: file)
        }
    }
    
    func deleteFiles(files: [ILibraryFile]) {
        for file in files {
            if let oldFileThumbPath = file.fileOreginalUrl?.path {
                try? self.fileManager.removeItem(atPath: oldFileThumbPath)
            }
            
            if let fileThumbPath = file.fileThumbUrl?.path {
                try? self.fileManager.removeItem(atPath: fileThumbPath)
            }
        }
    }
    
    func isExistFile(file: ILibraryFile, isThumb: Bool) -> Bool {
        guard let url = isThumb ? file.fileThumbUrl : file.fileOreginalUrl else {
            return false
        }
        return self.fileExists(atPath: url.path)
    }
    
}

extension STFileSystem {
        
    func fileExists(atPath path: String) -> Bool {
        return self.fileManager.fileExists(atPath: path)
    }
    
    func remove(file url: URL) {
        guard self.fileExists(atPath: url.path) else {
            return
        }
        do {
            try self.fileManager.removeItem(at: url)
        } catch {
        }
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
    
    func createDirectory(url: URL) throws {
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    func updateUrlDataSize(url: URL) {
        
        let megabytes: Double = STAppSettings.current.advanced.cacheSize.bytesUnits.megabytes
        guard let cacheURL = self.url(for: .storage(type: .server(type: nil))),  url.path.contains(cacheURL.path) else {
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
    
    static func privateKeyUrl(filePath: String? = nil) -> URL? {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        var result = url.appendingPathComponent("private")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: result.path) {
            try? fileManager.createDirectory(at: result, withIntermediateDirectories: true, attributes: nil)
        }
        
        if let filePath = filePath {
            result = result.appendingPathComponent(filePath)
        }
                        
        return result
    }
    
}

extension STFileSystem {
    
    class DiskStatus {

        //MARK: Formatter MB only
        class func MBFormatter(_ bytes: Int64) -> String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = ByteCountFormatter.Units.useMB
            formatter.countStyle = ByteCountFormatter.CountStyle.decimal
            formatter.includesUnit = false
            return formatter.string(fromByteCount: bytes) as String
        }

        //MARK: Get String Value
        class var totalDiskSpaceStr: String {
            get {
                return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
            }
        }

        class var freeDiskSpaceStr: String {
            get {
                return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
            }
        }

        class var usedDiskSpaceStr: String {
            get {
                return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
            }
        }


        //MARK: Get raw value
        class var totalDiskSpaceInBytes: Int64 {
            get {
                do {
                    let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                    let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
                    return space!
                } catch {
                    return 0
                }
            }
        }

        class var freeDiskSpaceInBytes: Int64 {
            get {
                do {
                    let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                    let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
                    return freeSpace!
                } catch {
                    return 0
                }
            }
        }

        class var usedDiskSpaceInBytes: Int64 {
            get {
                let usedSpace = totalDiskSpaceInBytes - freeDiskSpaceInBytes
                return usedSpace
            }
        }
        
        class var freeDiskSpaceUnits: STBytesUnits {
            let freeDiskSpace = self.freeDiskSpaceInBytes
            return STBytesUnits(bytes: freeDiskSpace)
        }

        class var usedDiskSpaceUnits: STBytesUnits {
            let usedDiskSpaceInBytes = self.usedDiskSpaceInBytes
            return STBytesUnits(bytes: usedDiskSpaceInBytes)
        }

    }
    
}

extension STFileSystem {
    
    enum FileSystemError: IError {
        case incorrectUrl
        
        var message: String {
            switch self {
            case .incorrectUrl:
                return "incorrect_url"
            }
        }
    }
    
    enum FolderType {
        
        case storage(type: CacheType)
        case tmp
        
        var stringValue: String {
            switch self {
            case .storage(let type):
                return "storage/" + "\(type.stringValue)"
            case .tmp:
                return "tmp"
            }
        }
        
        static var allCases: [FolderType] {
            return [.storage(type: .local(type: .oreginals)),
                    .storage(type: .local(type: .thumbs)),
                    .storage(type: .server(type: .oreginals)),
                    .storage(type: .server(type: .thumbs)),
                    .tmp]
        }
        
    }
    
    enum CacheType {
                
        case local(type: FileType? = nil)
        case server(type: FileType? = nil)
                
        var name: String {
            switch self {
            case .local:
                return "local"
            case .server:
                return "server"
            }
        }
        
        var stringValue: String {
            switch self {
            case .local(let type):
                var result = self.name
                if let type = type {
                    result = result + "/" + type.stringValue
                }
                return result
            case .server(let type):
                var result = self.name
                if let type = type {
                    result = result + "/" + type.stringValue
                }
                return result
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
    
    struct File {
        let type: FolderType
        let fileName: String
    }
    
}


extension FileManager {

    struct File {
        let path: String
        let size: STBytesUnits
        let dateCreation: Date?
        let dateModification: Date?
    }
    
    fileprivate func subDirectories(atPath: String) -> [String]? {
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
    
    fileprivate func subUrls(atPath: String) -> [URL]? {
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
    
    fileprivate func scanFolder(_ folderPath: String) -> (size: STBytesUnits, files: [File]) {
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


extension FileManager {
    
    func clearTmpDirectory() {
        do {
            let tmpDirectory = try contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach {[unowned self] file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try self.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
}
