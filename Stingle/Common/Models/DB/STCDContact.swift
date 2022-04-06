//
//  STSDContact+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDContact)
public class STCDContact: NSManagedObject {

}

extension STCDContact: IManagedSynchObject {
    
    func update(model: STContact) {
        self.email = model.email
        self.publicKey = model.publicKey
        self.userId = model.userId
        self.dateUsed = model.dateUsed
        self.dateModified = model.dateModified
        self.identifier = model.identifier
    }

    func createModel() throws -> STContact {
        return try STContact(model: self)
    }
    
    func mastUpdate(with model: STContact) -> Bool {
        return self.identifier == model.identifier
    }
    
}
