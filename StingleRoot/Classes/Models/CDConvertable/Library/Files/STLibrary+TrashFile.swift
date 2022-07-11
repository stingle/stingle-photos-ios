//
//  STLibraryTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.O
//

import CoreData

extension STLibrary {
    
    open class TrashFile: File<STCDTrashFile> {
        
        
        public override var dbSet: DBSet {
            return .trash
        }
        
        required public init(model: STCDTrashFile) throws {
            try super.init(file: model.file,
                           version: model.version,
                           headers: model.headers,
                           dateCreated: model.dateCreated,
                           dateModified: model.dateModified,
                           isRemote: model.isRemote,
                           isSynched: model.isSynched,
                           managedObjectID: model.objectID)
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
        
        override init(fileName: String, version: String, headers: String, dateCreated: Date, dateModified: Date, isRemote: Bool, isSynched: Bool, managedObjectID: NSManagedObjectID?) {
            super.init(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, managedObjectID: managedObjectID)
        }
        
        override init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, isSynched: Bool?, managedObjectID: NSManagedObjectID?) throws {
            try super.init(file: file, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, managedObjectID: managedObjectID)
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
            
            return TrashFile(fileName: fileName,
                             version: version,
                             headers: headers,
                             dateCreated: dateCreated,
                             dateModified: dateModified,
                             isRemote: isRemote,
                             isSynched: isSynched,
                             managedObjectID: managedObjectID) as! Self
            
        }
        
        public override func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil) -> Self {
            return self.copy(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, managedObjectID: self.managedObjectID)
        }
        
    }
    
}
