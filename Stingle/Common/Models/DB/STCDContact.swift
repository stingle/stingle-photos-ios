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
    
    func diffStatus(with model: Model) -> STDataBase.ModelDiffStatus {
        guard self.identifier == model.identifier else { return .none }
        guard let dateModified = self.dateModified else { return .low }
        if dateModified == model.dateModified {
            return .equal
        }
        if dateModified < model.dateModified {
            return .low
        }
        return .high
    }
    
}
