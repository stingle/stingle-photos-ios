//
//  STLibraryFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import Foundation
import CoreData

extension STLibrary {
            
    class File<CDModel: STCDFile>: FileBase, ICDSynchConvertable {
                
        let managedObjectID: NSManagedObjectID?
                                
        required init(from decoder: Decoder) throws {
            self.managedObjectID = nil
            try super.init(from: decoder)
        }
        
        init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, isSynched: Bool?, searchIndexes: [STLibrary.SearchIndex]?, managedObjectID: NSManagedObjectID?) throws {
            self.managedObjectID = managedObjectID
            try super.init(file: file, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, searchIndexes: searchIndexes)
        }
                
        init(fileName: String, version: String, headers: String, dateCreated: Date, dateModified: Date, isRemote: Bool, isSynched: Bool, searchIndexes: [STLibrary.SearchIndex]?, managedObjectID: NSManagedObjectID?) {
            self.managedObjectID = managedObjectID
            super.init(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, searchIndexes: searchIndexes)
        }
                
        required convenience init(model: CDModel) throws {
            let searchIndexes: [SearchIndex]? = try model.searchIndexes?.compactMap({ cdSearchIndex in
                guard let cdSearchIndex = cdSearchIndex as? STCDFileSearchIndex else {
                    return nil
                }
                return try SearchIndex(model: cdSearchIndex)
            })

            try self.init(file: model.file,
                          version: model.version,
                          headers: model.headers,
                          dateCreated: model.dateCreated,
                          dateModified: model.dateModified,
                          isRemote: model.isRemote,
                          isSynched: model.isSynched,
                          searchIndexes: searchIndexes,
                          managedObjectID: model.objectID)
        }
        
        
        
        func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil, managedObjectID: NSManagedObjectID? = nil) -> Self {

            let fileName = fileName ?? self.file
            let version = version ?? self.version
            let headers = headers ?? self.headers
            let dateCreated = dateCreated ?? self.dateCreated
            let dateModified = dateModified ?? self.dateModified
            let isRemote = isRemote ?? self.isRemote
            let managedObjectID = managedObjectID ?? self.managedObjectID
            let isSynched = isSynched ?? self.isSynched

            return File(fileName: fileName,
                        version: version,
                        headers: headers,
                        dateCreated: dateCreated,
                        dateModified: dateModified,
                        isRemote: isRemote,
                        isSynched: isSynched,
                        searchIndexes: self.searchIndexes,
                        managedObjectID: managedObjectID) as! Self

        }
        
        func updateLowMode(model: CDModel) {
            model.isRemote = self.isRemote
        }
        
        //MARK: - ICDSynchConvertable
        
        func toManagedModelJson() throws -> [String : Any] {
            var json: [String: Any] = ["file": self.file, "version": self.version, "headers": self.headers, "dateCreated": self.dateCreated, "dateModified": self.dateModified, "isRemote": isRemote, "identifier": self.identifier, "isSynched": self.isSynched]
            if let searchIndexes = self.searchIndexes?.map({ $0.toManagedModelJson() }) {
                json["searchIndexes"] = searchIndexes
            }
            return json
        }
        
        func update(model: CDModel) {
            model.file = self.file
            model.version = self.version
            model.headers = self.headers
            model.dateCreated = self.dateCreated
            model.dateModified = self.dateModified
            model.isRemote = self.isRemote
            model.isSynched = self.isSynched
            model.identifier = self.identifier
        }
        
        func diffStatus(with rhs: CDModel) -> STDataBase.ModelModifyStatus {
            guard self.identifier == rhs.identifier else {
                return .none
            }
            
            guard let rhsDateModified = rhs.dateModified else { return .high(type: .upgrade) }
            
            let selfDateModified = self.dateModified
            
            let selfVersion = Int(self.version) ?? .zero
            let rhsVersion = Int(rhs.version ?? "") ?? .zero
            
            if selfVersion < rhsVersion {
                return .low
            } else if selfVersion > rhsVersion {
                return .high(type: .upgrade)
            } else if selfDateModified > rhsDateModified {
                return .high(type: .update)
            } else if selfDateModified < rhsDateModified {
                return .low
            }
            
            return .equal
        }
                        
        static func > (lhs: STLibrary.File<CDModel>, rhs: STLibrary.File<CDModel>) -> Bool {
            return lhs > rhs
        }
        
    }
    
}
