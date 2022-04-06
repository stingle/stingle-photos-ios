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
public class STCDFile: NSManagedObject {
   

}

extension STCDFile: IManagedSynchObject {
    
    func update(model: STLibrary.File) {
        self.file = model.file
        self.version = model.version
        self.headers = model.headers
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.isRemote = model.isRemote
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STLibrary.File {
        return try STLibrary.File(model: self)
    }
    
    func mastUpdate(with model: STLibrary.File) -> Bool {
        guard self.identifier == model.identifier else {
            return false
        }
        
        guard let dateModified = self.dateModified else { return true }
        let lhsVersion = Int(self.version ?? "") ?? .zero
        let rhsVersion = Int(model.version) ?? .zero
        
        return lhsVersion == rhsVersion ? dateModified < model.dateModified : lhsVersion < rhsVersion
    }
    
}
