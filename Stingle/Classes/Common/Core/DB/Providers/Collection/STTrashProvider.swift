//
//  STTrashProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

protocol ITrashProviderObserver {
    
}

extension STDataBase {
    
    class TrashProvider: DataBaseCollectionProvider<STLibrary.TrashFile, STCDTrashFile, STLibrary.DeleteFile.Trash> {
        
        override func getInsertObjects(with trashFiles: [STLibrary.TrashFile]) throws -> (json: [[String : Any]], lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            try trashFiles.forEach { (file) in
                let json = try file.toManagedModelJson()
                jsons.append(json)
                let currentLastDate = lastDate ?? file.dateModified
                if currentLastDate <= file.dateModified {
                    lastDate = file.dateModified
                }
            }
            
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            return (jsons, myLastDate)
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
