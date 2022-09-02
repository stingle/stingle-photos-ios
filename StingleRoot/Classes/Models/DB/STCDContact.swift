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
public class STCDContact: NSManagedObject, ISynchManagedObject {
    
    public var dateCreated: Date? {
        return self.dateUsed
    }
    
}
