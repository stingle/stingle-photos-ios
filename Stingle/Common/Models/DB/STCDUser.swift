//
//  STCDUser+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDUser)
public class STCDUser: NSManagedObject {
    
    
}

extension STCDUser: IManagedObject {
    
    func update(model: STUser) {
        self.email = model.email
        self.homeFolder = model.homeFolder
        self.isKeyBackedUp = model.isKeyBackedUp
        self.token = model.token
        self.userId = model.userId
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STUser {
        return try STUser(model: self)
    }
    
}
