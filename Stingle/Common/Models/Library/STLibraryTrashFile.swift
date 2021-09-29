//
//  STLibraryTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.O
//

import CoreData

extension STLibrary {
    
    class TrashFile: File {
        
        typealias ManagedModel = STCDTrashFile
        
        override var dbSet: DBSet {
            return .trash
        }
        
        required init(model: STCDTrashFile) throws {
            try super.init(file: model.file,
                           version: model.version,
                           headers: model.headers,
                           dateCreated: model.dateCreated,
                           dateModified: model.dateModified,
                           isRemote: model.isRemote,
                           managedObjectID: model.objectID)
        }
        
        required init(model: STCDFile) throws {
            fatalError("init(model:) has not been implemented")
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
        
        override init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, managedObjectID: NSManagedObjectID?) throws {
            try super.init(file: file, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, managedObjectID: managedObjectID)
        }
        
    }
    
}
