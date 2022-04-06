//
//  STAlbumsProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumsProvider: SyncCollectionProvider<STCDAlbum, STLibrary.DeleteFile.Album> {
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Album], in context: NSManagedObjectContext) throws -> (models: [STCDAlbum], date: Date) {
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.backgroundContext
            let albumIds = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.albumId
            }
            
            let fetchRequest = NSFetchRequest<STCDAlbum>(entityName: STCDAlbum.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "albumId IN %@", albumIds)
            let deleteingCDItems = try context.fetch(fetchRequest)
            var deleteItems = [STCDAlbum]()
            let groupCDItems = Dictionary(grouping: deleteingCDItems, by: { $0.albumId })
            let defaultDate =  Date.defaultDate
            var lastDate = defaultDate
            
            for delete in deleteFiles {
                lastDate = max(delete.date, lastDate)
                let cdModels = groupCDItems[delete.albumId]
                if let deliteObjects = cdModels?.filter( { $0.dateModified ?? defaultDate <= delete.date} ) {
                    deleteItems.append(contentsOf: deliteObjects)
                }
            }
            return (deleteItems, lastDate)
        }
        
        override func getObjects(by models: [STLibrary.Album], in context: NSManagedObjectContext) throws -> [STCDAlbum] {
            guard !models.isEmpty else {
                return []
            }
            let identifiers = models.compactMap { (deleteFile) -> String in
                return deleteFile.identifier
            }
            let fetchRequest = NSFetchRequest<STCDAlbum>(entityName: STCDAlbum.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "\(#keyPath(STCDAlbum.identifier)) IN %@", identifiers)
            let cdItems = try context.fetch(fetchRequest)
            return cdItems
        }
        
        override func updateObjects(by models: [STLibrary.Album], managedModels: [STCDAlbum], in context: NSManagedObjectContext) {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first {
                    let cdModel = keyValue.value.first
                    cdModel?.update(model: model)
                }
            }
            
        }
                
    }

}
