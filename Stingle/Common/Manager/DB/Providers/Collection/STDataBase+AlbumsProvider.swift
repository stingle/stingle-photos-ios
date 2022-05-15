//
//  STAlbumsProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumsProvider: SyncProvider<STLibrary.Album, STLibrary.DeleteFile.Album> {
        
        override var providerType: SyncProviderType {
            return .albums
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
                if let key = keyValue.key, let model = modelsGroup[key]?.first, let cdModel = keyValue.value.first {
                    model.update(model: cdModel)
                }
            }
            
        }
                
    }

}
