//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: DataBaseCollectionProvider<STContact, STCDContact, STLibrary.DeleteFile.Contact> {
        
        
        override func getInsertObjects(with contacts: [STContact]) throws -> (json: [[String : Any]], lastDate: Date) {
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
            
            return (jsons, myLastDate)
        }
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Contact], in context: NSManagedObjectContext) throws -> (models: [STCDContact], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.newBackgroundContext()
            let fileNames = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.contactId
            }
            
            let fetchRequest = NSFetchRequest<STCDContact>(entityName: STCDContact.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "userId IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            var deleteItems = [STCDContact]()
            let groupCDItems = Dictionary(grouping: deleteingCDItems, by: { $0.userId })
            let defaultDate =  Date.defaultDate
            var lastDate = defaultDate
            
            for delete in deleteFiles {
                lastDate = max(delete.date, lastDate)
                let cdModels = groupCDItems[delete.contactId]
                if let deliteObjects = cdModels?.filter( { $0.dateModified ?? defaultDate <= delete.date} ) {
                    deleteItems.append(contentsOf: deliteObjects)
                }
            }
            return (deleteItems, lastDate)
        }
        
    }

}
