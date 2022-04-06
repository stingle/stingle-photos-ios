//
//  STGalleryProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class GalleryProvider: SyncCollectionProvider<STCDFile, STLibrary.DeleteFile.Gallery> {
                
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Gallery], in context: NSManagedObjectContext) throws -> (models: [STCDFile], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let fileNames = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.file
            }
            
            let fetchRequest = NSFetchRequest<STCDFile>(entityName: STCDFile.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "file IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            var deleteItems = [STCDFile]()
            let groupCDItems = Dictionary(grouping: deleteingCDItems, by: { $0.file })
            let defaultDate =  Date.defaultDate
            var lastDate = defaultDate
            
            for delete in deleteFiles {
                lastDate = max(delete.date, lastDate)
                let cdModels = groupCDItems[delete.file]
                if let deliteObjects = cdModels?.filter( { $0.dateModified ?? defaultDate <= delete.date} ) {
                    deleteItems.append(contentsOf: deliteObjects)
                }
            }
            return (deleteItems, lastDate)
        }
        
        override func getObjects(by models: [STLibrary.File], in context: NSManagedObjectContext) throws -> [STCDFile] {
            guard !models.isEmpty else {
                return []
            }
            let fileNames = models.compactMap { (deleteFile) -> String in
                return deleteFile.identifier
            }
            let fetchRequest = NSFetchRequest<STCDFile>(entityName: STCDFile.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            return deleteingCDItems
        }
        
        override func updateObjects(by models: [STLibrary.File], managedModels: [STCDFile], in context: NSManagedObjectContext) {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first {
                    let cdModel = keyValue.value.first
                    cdModel?.update(model: model)
                }
            }
            
        }
        
        func fetchAll(for fileNames: [String]) -> [STLibrary.File] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDFile.file)) IN %@", fileNames)
            let result = self.fetchObjects(predicate: predicate)
            return result
        }
        
        func fetch(fileNames: [String], context: NSManagedObjectContext) -> [STCDFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDFile.file)) IN %@", fileNames)
            let fetchRequest = NSFetchRequest<STCDFile>(entityName: STCDFile.entityName)
            fetchRequest.predicate = predicate
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }

    }
    
}

