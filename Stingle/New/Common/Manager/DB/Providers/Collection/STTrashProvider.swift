//
//  STTrashProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class TrashProvider: DataBaseCollectionProvider<STLibrary.TrashFile, STCDTrashFile, STLibrary.DeleteFile.Trash> {
        
        override func getInsertObjects(with trashFiles: [STLibrary.TrashFile]) throws -> (json: [[String : Any]], objIds: [String: STLibrary.TrashFile], lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            var objIds = [String: STLibrary.TrashFile]()
            
            try trashFiles.forEach { (file) in
                let json = try file.toManagedModelJson()
                jsons.append(json)
                objIds[file.file] = file
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
        
        override func syncUpdateModels(objIds: [String : STLibrary.TrashFile], insertedObjectIDs: [NSManagedObjectID], context: NSManagedObjectContext) throws {
           
            let fetchRequest = NSFetchRequest<STCDTrashFile>(entityName: STCDTrashFile.entityName)
            fetchRequest.includesSubentities = false
            let keys: [String] = Array(objIds.keys)
            fetchRequest.predicate = NSPredicate(format: "file IN %@", keys)
            let items = try context.fetch(fetchRequest)
            
            items.forEach { (item) in
                if let file = item.file, let model = objIds[file] {
                    item.update(model: model, context: context)
                }
            }

        }
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Trash], in context: NSManagedObjectContext) throws -> (models: [STCDTrashFile], date: Date) {
           
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.newBackgroundContext()
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
        
    }

}
