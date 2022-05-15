//
//  STGalleryProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class GalleryProvider: SyncProvider<STLibrary.GaleryFile, STLibrary.DeleteFile.Gallery> {
        
        override var providerType: SyncProviderType {
            return .gallery
        }
        
        override func getObjects(by models: [STLibrary.GaleryFile], in context: NSManagedObjectContext) throws -> [STDataBase.CollectionProvider<STLibrary.GaleryFile>.ManagedObject] {
            guard !models.isEmpty else {
                return []
            }
            let fileNames = models.compactMap { (deleteFile) -> String in
                return deleteFile.identifier
            }
            let fetchRequest = NSFetchRequest<STCDGaleryFile>(entityName: STCDGaleryFile.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            return deleteingCDItems
        }

        override func updateObjects(by models: [STLibrary.GaleryFile], managedModels: [STDataBase.CollectionProvider<STLibrary.GaleryFile>.ManagedObject], in context: NSManagedObjectContext) throws {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first, let cdModel = keyValue.value.first {
                    model.update(model: cdModel)
                }
            }
        }

        func fetchAll(for fileNames: [String]) -> [STLibrary.GaleryFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDGaleryFile.file)) IN %@", fileNames)
            let result = self.fetchObjects(predicate: predicate)
            return result
        }

        func fetch(fileNames: [String], context: NSManagedObjectContext) -> [STCDGaleryFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDGaleryFile.file)) IN %@", fileNames)
            let fetchRequest = NSFetchRequest<STCDGaleryFile>(entityName: STCDGaleryFile.entityName)
            fetchRequest.predicate = predicate
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }
        
    }
    
}
