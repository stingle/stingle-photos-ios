//
//  STLibraryTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.O
//

import Foundation

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
                           isRemote: model.isRemote)
        }
        
        required init(model: STCDFile) throws {
            fatalError("init(model:) has not been implemented")
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
        
    }
    
}
