//
//  STCDTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import Foundation
import CoreData

@objc(STCDTrashFile)
public class STCDTrashFile: NSManagedObject {
    
}

extension STCDTrashFile: IManagedSynchObject {
    
    func update(model: STLibrary.TrashFile) {
        self.file = model.file
        self.version = model.version
        self.headers = model.headers
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.isRemote = model.isRemote
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STLibrary.TrashFile {
        return try STLibrary.TrashFile(model: self)
    }
    
    func mastUpdate(with model: STLibrary.TrashFile) -> Bool {
        guard self.identifier == model.identifier else {
            return false
        }
        
        guard let dateModified = self.dateModified else { return true }
        let lhsVersion = Int(self.version ?? "") ?? .zero
        let rhsVersion = Int(model.version) ?? .zero
        
        return lhsVersion == rhsVersion ? dateModified < model.dateModified : lhsVersion < rhsVersion
    }
    
}
