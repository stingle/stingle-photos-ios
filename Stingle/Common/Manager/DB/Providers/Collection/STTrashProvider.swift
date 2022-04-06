//
//  STTrashProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class TrashProvider: SyncCollectionProvider<STCDTrashFile, STLibrary.DeleteFile.Trash> {
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Trash], in context: NSManagedObjectContext) throws -> (models: [STCDTrashFile], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.backgroundContext
            let fileNames = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.fileName
            }
            
            let fetchRequest = NSFetchRequest<STCDTrashFile>(entityName: STCDTrashFile.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "file IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            var deleteItems = [STCDTrashFile]()
            let groupCDItems = Dictionary(grouping: deleteingCDItems, by: { $0.file })
            let defaultDate =  Date.defaultDate
            var lastDate = defaultDate
            
            for delete in deleteFiles {
                lastDate = max(delete.date, lastDate)
                let cdModels = groupCDItems[delete.fileName]
                if let deliteObjects = cdModels?.filter( { $0.dateModified ?? defaultDate <= delete.date} ) {
                    deleteItems.append(contentsOf: deliteObjects)
                }
            }
            return (deleteItems, lastDate)
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
