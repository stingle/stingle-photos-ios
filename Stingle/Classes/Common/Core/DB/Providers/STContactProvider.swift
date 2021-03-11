//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: DataBaseProvider<STContact, STCDContact> {
        
        override func newBatchInsertRequest(with contacts: [STContact], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
            
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            
            try contacts.forEach { (contact) in
                let json = try contact.toManagedModelJson()
                jsons.append(json)
                let currentLastDate = lastDate ?? contact.dateModified
                if currentLastDate <= contact.dateModified {
                    lastDate = contact.dateModified
                }
            }
            
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let insertRequest = NSBatchInsertRequest(entityName: STCDContact.entityName, objects: jsons)
            insertRequest.resultType = .statusOnly
            return (insertRequest, myLastDate)
        }
        
    }

}
