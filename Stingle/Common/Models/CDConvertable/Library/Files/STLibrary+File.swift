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
        
        init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, isSynched: Bool?, managedObjectID: NSManagedObjectID?) throws {
            self.managedObjectID = managedObjectID
            try super.init(file: file, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched)
        }
                
        init(fileName: String, version: String, headers: String, dateCreated: Date, dateModified: Date, isRemote: Bool, isSynched: Bool, managedObjectID: NSManagedObjectID?) {
            self.managedObjectID = managedObjectID
            super.init(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched)
        }
                
        required convenience init(model: CDModel) throws {
            try self.init(file: model.file,
                          version: model.version,
                          headers: model.headers,
                          dateCreated: model.dateCreated,
                          dateModified: model.dateModified,
                          isRemote: model.isRemote,
                          isSynched: model.isSynched,
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
                        managedObjectID: managedObjectID) as! Self

        }
        
    
        
        //MARK: - ICDSynchConvertable
        
        func toManagedModelJson() throws -> [String : Any] {
            return ["file": self.file, "version": self.version, "headers": self.headers, "dateCreated": self.dateCreated, "dateModified": self.dateModified, "isRemote": isRemote, "identifier": self.identifier, "isSynched": self.isSynched]
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
        
        func diffStatus(with rhs: CDModel) -> STDataBase.ModelDiffStatus {
            guard self.identifier == rhs.identifier else {
                return .none
            }
            
            guard let rhsDateModified = rhs.dateModified else { return .high }
            let lhsDateModified = self.dateModified
            
            let lhsVersion = Int(self.version) ?? .zero
            let rhsVersion = Int(rhs.version ?? "") ?? .zero
                        
            if lhsVersion == rhsVersion ? lhsDateModified < rhsDateModified : lhsVersion < rhsVersion {
                return .low
            } else if lhsVersion == rhsVersion && lhsDateModified == rhs.dateModified {
                return .equal
            }
            return .high
        }
                        
        static func > (lhs: STLibrary.File<CDModel>, rhs: STLibrary.File<CDModel>) -> Bool {
            return lhs > rhs
        }
        
    }
    
}
