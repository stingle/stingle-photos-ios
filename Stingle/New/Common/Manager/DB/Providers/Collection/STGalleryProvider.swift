//
//  STGalleryProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class GalleryProvider: DataBaseCollectionProvider<STCDFile, STLibrary.DeleteFile.Gallery> {
        
        override func getInsertObjects(with files: [STLibrary.File]) throws -> (json: [[String : Any]], objIds: [String: STLibrary.File], lastDate: Date)  {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            var objIds = [String: STLibrary.File]()
            
            try files.forEach { (file) in
                let json = try file.toManagedModelJson()
                jsons.append(json)
                objIds[file.identifier] = file
                let currentLastDate = lastDate ?? file.dateModified
                if currentLastDate <= file.dateModified {
                    lastDate = file.dateModified
                }
            }
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            return (jsons, objIds, myLastDate)
        }
        
        override func syncUpdateModels(objIds: [String : STLibrary.File], insertedObjectIDs: [NSManagedObjectID], context: NSManagedObjectContext) throws {
           
            let fetchRequest = NSFetchRequest<STCDFile>(entityName: STCDFile.entityName)
            fetchRequest.includesSubentities = false
            let keys: [String] = Array(objIds.keys)
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", keys)
            let items = try context.fetch(fetchRequest)
            
            items.forEach { (item) in
                if let file = item.identifier, let model = objIds[file] {
                    item.update(model: model, context: context)
                }
            }

        }
                
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
                    cdModel?.update(model: model, context: context)
                }
            }
            
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

