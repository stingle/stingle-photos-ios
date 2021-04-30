//
//  STCDTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import Foundation
import CoreData

@objc(STCDTrashFile)
public class STCDTrashFile: NSManagedObject, IManagedObject {
    
    var identifier: String? {
        return self.file
    }

    func update(model: STLibrary.TrashFile, context: NSManagedObjectContext) {
        self.file = model.file
        self.version = model.version
        self.headers = model.headers
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.isRemote = model.isRemote
    }
    
    func createModel() throws -> STLibrary.TrashFile {
        return try STLibrary.TrashFile(model: self)
    }
        
}
