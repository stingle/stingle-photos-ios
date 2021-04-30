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
public class STCDUser: NSManagedObject, IManagedObject {
    
    var identifier: String? {
        return self.userId
    }
    
    func update(model: STUser, context: NSManagedObjectContext) {
        self.email = model.email
        self.homeFolder = model.homeFolder
        self.isKeyBackedUp = model.isKeyBackedUp
        self.token = model.token
        self.userId = model.userId
    }
    
    func createModel() throws -> STUser {
        return try STUser(model: self)
    }

}
