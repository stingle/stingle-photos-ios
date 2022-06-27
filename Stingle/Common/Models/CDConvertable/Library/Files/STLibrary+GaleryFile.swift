//
//  STLibrary+GaleryFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/6/22.
//

import CoreData

extension STLibrary {
    
    class GaleryFile: File<STCDGaleryFile> {
        
        typealias ManagedModel = STCDGaleryFile
        
        override var dbSet: DBSet {
            return .galery
        }
        
        required init(model: STCDGaleryFile) throws {
            try super.init(file: model.file,
                           version: model.version,
                           headers: model.headers,
                           dateCreated: model.dateCreated,
                           dateModified: model.dateModified,
                           isRemote: model.isRemote,
                           isSynched: model.isSynched,
                           managedObjectID: model.objectID)
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
        
        override init(fileName: String, version: String, headers: String, dateCreated: Date, dateModified: Date, isRemote: Bool, isSynched: Bool, managedObjectID: NSManagedObjectID?) {
            super.init(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, managedObjectID: managedObjectID)
        }
        
        override func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil) -> Self {
            return self.copy(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, managedObjectID: self.managedObjectID)
        }
        
        override func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil, managedObjectID: NSManagedObjectID? = nil) -> Self {
            
            let fileName = fileName ?? self.file
            let version = version ?? self.version
            let headers = headers ?? self.headers
            let dateCreated = dateCreated ?? self.dateCreated
            let dateModified = dateModified ?? self.dateModified
            let isRemote = isRemote ?? self.isRemote
            let managedObjectID = managedObjectID ?? self.managedObjectID
            let isSynched = isSynched ?? self.isSynched
            
            return GaleryFile(fileName: fileName,
                             version: version,
                             headers: headers,
                             dateCreated: dateCreated,
                             dateModified: dateModified,
                             isRemote: isRemote,
                             isSynched: isSynched,
                             managedObjectID: managedObjectID) as! Self
            
        }
        
    }
    
}


