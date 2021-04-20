//
//  STCDFile+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDFile)
public class STCDFile: NSManagedObject, IManagedObject {
   
    func update(model: STLibrary.File, context: NSManagedObjectContext) {
        self.file = model.file
        self.version = model.version
        self.headers = model.headers
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.isRemote = model.isRemote
    }
    
    func createModel() throws -> STLibrary.File {
        return try STLibrary.File(model: self)
    }

}
