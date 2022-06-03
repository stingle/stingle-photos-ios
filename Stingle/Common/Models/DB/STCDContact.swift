//
//  STSDContact+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation

extension STCDContact: ISynchManagedObject {
    
    var dateCreated: Date? {
        return self.dateUsed
    }
    
}
