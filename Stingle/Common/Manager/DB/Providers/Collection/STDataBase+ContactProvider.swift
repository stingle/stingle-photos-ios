//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: SyncProvider<STContact, STLibrary.DeleteFile.Contact> {
        
        override var providerType: SyncProviderType {
            return .contact
        }
        
        override func updateObjects(by models: [STContact], managedModels: [STDataBase.CollectionProvider<STContact>.ManagedObject], in context: NSManagedObjectContext) throws {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first, let cdModel = keyValue.value.first {
                    model.update(model: cdModel)
                }
            }
        }
        
        override func getObjects(by models: [STContact], in context: NSManagedObjectContext) throws -> [STDataBase.CollectionProvider<STContact>.ManagedObject] {
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
