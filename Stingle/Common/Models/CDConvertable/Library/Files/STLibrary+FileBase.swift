//
//  STLibrary+FileBase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/11/22.
//

import CoreData

protocol ILibraryFile {
    
    var dbSet: STLibrary.DBSet { get }
    var file: String { get }
    var version: String { get }
    var headers: String { get }
    var dateCreated: Date { get }
    var dateModified: Date { get }
    var isRemote: Bool { get }
    var isSynched: Bool { get }
    
    var identifier: String { get }
    
    var fileThumbUrl: URL? { get }
    var fileOreginalUrl: URL? { get }
    
    var decryptsHeaders: STHeaders { get }
    func getImageParameters(isThumb: Bool) -> [String: String]
            
}

extension STLibrary {
    
    class FileBase: Codable, ILibraryFile {
        
        private enum CodingKeys: String, CodingKey {
            case file = "file"
            case version = "version"
            case headers = "headers"
            case dateCreated = "dateCreated"
            case dateModified = "dateModified"
        }
        
        let file: String
        let version: String
        let headers: String
        let dateCreated: Date
        let dateModified: Date
        let isRemote: Bool
        let isSynched: Bool
        
        var identifier: String {
            return self.file
        }
        
        var dbSet: DBSet {
            return .none
        }
        
        lazy var decryptsHeaders: STHeaders = {
            let result = STApplication.shared.crypto.getHeaders(headersStrs: self.headers)
            return result
        }()
        
        var fileThumbUrl: URL? {
            let fileSystem = STApplication.shared.fileSystem
            return fileSystem.fileThumbUrl(fileName: self.file, isRemote: self.isRemote && self.isSynched)
        }
        
        var fileOreginalUrl: URL? {
            let fileSystem = STApplication.shared.fileSystem
            return fileSystem.fileOreginalUrl(fileName: self.file, isRemote: self.isRemote && self.isSynched)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.file = try container.decode(String.self, forKey: .file)
            self.version = try container.decode(String.self, forKey: .version)
            self.headers = try container.decode(String.self, forKey: .headers)
            let dateCreatedStr = try container.decode(String.self, forKey: .dateCreated)
            let dateModifiedStr = try container.decode(String.self, forKey: .dateModified)
            guard let dateCreated = UInt64(dateCreatedStr), let dateModified = UInt64(dateModifiedStr) else {
                throw LibraryError.parsError
            }
            self.dateCreated = Date(milliseconds: dateCreated)
            self.dateModified = Date(milliseconds: dateModified)
            self.isRemote = true
            self.isSynched = true
        }
        
        init(fileName: String, version: String, headers: String, dateCreated: Date, dateModified: Date, isRemote: Bool, isSynched: Bool) {
            self.file = fileName
            self.version = version
            self.headers = headers
            self.dateCreated = dateCreated
            self.dateModified = dateModified
            self.isRemote = isRemote
            self.isSynched = isSynched
        }
        
        init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, isSynched: Bool?) throws {
            guard let file = file,
                  let version = version,
                  let headers = headers,
                  let dateCreated = dateCreated,
                  let dateModified = dateModified,
                  let isSynched = isSynched
            else {
                throw LibraryError.parsError
            }

            self.file = file
            self.version = version
            self.headers = headers
            self.dateCreated = dateCreated
            self.dateModified = dateModified
            self.isRemote = isRemote
            self.isSynched = isSynched
        }
                
        func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil) -> Self {
            
            let fileName = fileName ?? self.file
            let version = version ?? self.version
            let headers = headers ?? self.headers
            let dateCreated = dateCreated ?? self.dateCreated
            let dateModified = dateModified ?? self.dateModified
            let isRemote = isRemote ?? self.isRemote
            let isSynched = isSynched ?? self.isSynched
            
            return FileBase(fileName: fileName,
                        version: version,
                        headers: headers,
                        dateCreated: dateCreated,
                        dateModified: dateModified,
                        isRemote: isRemote,
                        isSynched: isSynched) as! Self
            
        }
        
        func getImageParameters(isThumb: Bool) -> [String: String] {
            let isThumbStr = isThumb ? "1" : "0"
            return ["file": self.file, "set": "\(self.dbSet.rawValue)", "is_thumb": isThumbStr]
        }
        
        static func > (lhs: STLibrary.FileBase, rhs: STLibrary.FileBase) -> Bool {
            guard lhs.identifier == rhs.identifier else {
                return false
            }
            let lhsVersion = Int(lhs.version) ?? .zero
            let rhsVersion = Int(rhs.version) ?? .zero
            return lhsVersion == rhsVersion ? lhs.dateModified > rhs.dateModified : lhsVersion > rhsVersion
        }
        
    }
    
}
