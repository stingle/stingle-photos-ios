//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: SyncCollectionProvider<STCDContact, STLibrary.DeleteFile.Contact> {
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Contact], in context: NSManagedObjectContext) throws -> (models: [STCDContact], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.backgroundContext
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
                    cdModel?.update(model: model)
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
