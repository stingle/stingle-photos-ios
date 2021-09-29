//
//  STLibraryFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import Foundation
import CoreData

extension STLibrary {
        
    class File: Codable, ICDConvertable {
                
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
        var isRemote: Bool
        
        let managedObjectID: NSManagedObjectID?
        
        var identifier: String {
            return self.file
        }
        
        var dbSet: DBSet {
            return .file
        }
        
        lazy var decryptsHeaders: STHeaders = {
            let result = STApplication.shared.crypto.getHeaders(file: self)
            return result
        }()
        
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
            self.managedObjectID = nil
        }
        
        init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, managedObjectID: NSManagedObjectID?) throws {
            guard let file = file,
                  let version = version,
                  let headers = headers,
                  let dateCreated = dateCreated,
                  let dateModified = dateModified
            else {
                throw LibraryError.parsError
            }
            
            self.file = file
            self.version = version
            self.headers = headers
            self.dateCreated = dateCreated
            self.dateModified = dateModified
            self.isRemote = isRemote
            self.managedObjectID = managedObjectID
        }
        
        required convenience init(model: STCDFile) throws {
            try self.init(file: model.file,
                           version: model.version,
                           headers: model.headers,
                           dateCreated: model.dateCreated,
                           dateModified: model.dateModified,
                           isRemote: model.isRemote,
                           managedObjectID: model.objectID)
        }
        
        func toManagedModelJson() throws -> [String : Any] {
            return ["file": self.file, "version": self.version, "headers": self.headers, "dateCreated": self.dateCreated, "dateModified": self.dateModified, "isRemote": isRemote, "identifier": self.identifier]
        }
        
    }
    
}

extension STLibrary.File {
        
    var fileThumbUrl: URL? {
        let fileSystem = STApplication.shared.fileSystem
        return fileSystem.fileThumbUrl(fileName: self.file, isRemote: self.isRemote)
    }
    
    var fileOreginalUrl: URL? {
        let fileSystem = STApplication.shared.fileSystem
        return fileSystem.fileOreginalUrl(fileName: self.file, isRemote: self.isRemote)
    }
        
}
