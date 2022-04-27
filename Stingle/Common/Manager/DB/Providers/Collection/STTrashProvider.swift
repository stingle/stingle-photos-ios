//
//  STTrashProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class TrashProvider: SyncCollectionProvider<STCDTrashFile, STLibrary.DeleteFile.Trash> {
        
        override var providerType: SyncProviderType {
            return .trash
        }
        
        override func getObjects(by models: [STLibrary.TrashFile], in context: NSManagedObjectContext) throws -> [STCDTrashFile] {
            guard !models.isEmpty else {
                return []
            }
            let fileNames = models.compactMap { (deleteFile) -> String in
                return deleteFile.file
            }
            let fetchRequest = NSFetchRequest<STCDTrashFile>(entityName: STCDTrashFile.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", fileNames)
            let cdItems = try context.fetch(fetchRequest)
            return cdItems
        }
        
        override func updateObjects(by models: [STLibrary.TrashFile], managedModels: [STCDTrashFile], in context: NSManagedObjectContext) {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first {
                    let cdModel = keyValue.value.first
                    cdModel?.update(model: model)
                }
            }
        }
        
        func fetch(fileNames: [String], context: NSManagedObjectContext) -> [STCDTrashFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDTrashFile.file)) IN %@", fileNames)
            let fetchRequest = NSFetchRequest<STCDTrashFile>(entityName: STCDTrashFile.entityName)
            fetchRequest.predicate = predicate
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }
        
        func fetchAll(for fileNames: [String]) -> [STLibrary.TrashFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDTrashFile.file)) IN %@", fileNames)
            let result = self.fetchObjects(predicate: predicate)
            return result
        }
        
    }

}
