//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: SyncCollectionProvider<STCDContact, STLibrary.DeleteFile.Contact> {
        
        override func getInsertObjects(with contacts: [STContact]) throws -> (json: [[String : Any]], objIds: [String: STContact], lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            var objIds = [String: STContact]()
            
            try contacts.forEach { (contact) in
                let json = try contact.toManagedModelJson()
                jsons.append(json)
                objIds[contact.identifier] = contact
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
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", keys)
            let items = try context.fetch(fetchRequest)
            
            items.forEach { (item) in
                if let userId = item.identifier, let model = objIds[userId] {
                    item.update(model: model, context: context)
                }
            }

        }
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Contact], in context: NSManagedObjectContext) throws -> (models: [STCDContact], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.newBackgroundContext()
            let contactIds = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.contactId
            }
            let fetchRequest = NSFetchRequest<STCDContact>(entityName: STCDContact.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "userId IN %@", contactIds)
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
        
        override func updateObjects(by models: [STContact], managedModels: [STCDContact], in context: NSManagedObjectContext) {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first {
                    let cdModel = keyValue.value.first
                    cdModel?.update(model: model, context: context)
                }
            }
        }
        
        override func getObjects(by models: [STContact], in context: NSManagedObjectContext) throws -> [STCDContact] {
            guard !models.isEmpty else {
                return []
            }
            let userIds = models.compactMap { (deleteFile) -> String in
                return deleteFile.identifier
            }
            let fetchRequest = NSFetchRequest<STCDContact>(entityName: STCDContact.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", userIds)
            let deleteingCDItems = try context.fetch(fetchRequest)
            return deleteingCDItems
            
        }
        
    }

}
