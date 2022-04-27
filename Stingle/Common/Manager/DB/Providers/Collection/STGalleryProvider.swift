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
        
        override var providerType: SyncProviderType {
            return .gallery
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

