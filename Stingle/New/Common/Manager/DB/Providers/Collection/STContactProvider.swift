//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: DataBaseCollectionProvider<STContact, STCDContact, STLibrary.DeleteFile.Contact> {
        
        override func getInsertObjects(with contacts: [STContact]) throws -> (json: [[String : Any]], objIds: [String: STContact], lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            var objIds = [String: STContact]()
            
            try contacts.forEach { (contact) in
                let json = try contact.toManagedModelJson()
                jsons.append(json)
                objIds[contact.userId] = contact
                let currentLastDate = lastDate ?? contact.dateModified
                if currentLastDate <= contact.dateModified {
                    lastDate = contact.dateModified
                }
            }
            
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            return (jsons, objIds, myLastDate)
        }
        
        override func syncUpdateModels(objIds: [String : STContact], insertedObjectIDs: [NSManagedObjectID], context: NSManagedObjectContext) throws {
           
            let fetchRequest = NSFetchRequest<STCDContact>(entityName: STCDContact.entityName)
            fetchRequest.includesSubentities = false
            let keys: [String] = Array(objIds.keys)
            fetchRequest.predicate = NSPredicate(format: "userId IN %@", keys)
            let items = try context.fetch(fetchRequest)
            
            items.forEach { (item) in
                if let userId = item.userId, let model = objIds[userId] {
                    item.update(model: model, context: context)
                }
            }

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
