//
//  STAlbumFilesProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

public extension STDataBase.SyncProvider where Model.ManagedModel: STCDAlbumFile {
    
    func fetchObjects(albumID: String, fileNames: [String], context: NSManagedObjectContext? = nil) -> [Model] {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@ && \(#keyPath(STCDAlbumFile.identifier)) IN %@", albumID, fileNames)
        let result = self.fetchObjects(predicate: predicate)
        return result
    }
    
    func fetchObjects(albumID: String) -> [Model] {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
        let result = self.fetchObjects(predicate: predicate)
        return result
    }
    
    func fetchObjects(albumID: String, identifiers: [String]) -> [Model] {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@ && \(#keyPath(STCDAlbumFile.identifier)) IN %@", albumID, identifiers)
        let result = self.fetchObjects(predicate: predicate)
        return result
    }
    
    func fetch(albumID: String, fileNames: [String]? = nil, sortDescriptorsKeys: [String], ascending: Bool) -> [ManagedObject] {
        
        var predicate: NSPredicate!
        if let fileNames = fileNames {
            predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@ && \(#keyPath(STCDAlbumFile.file)) IN %@", albumID, fileNames)
        } else {
            predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
        }
        let context = self.container.viewContext
        return context.performAndWait { () -> [ManagedObject] in
            let fetchRequest = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entityName)
            fetchRequest.includesPropertyValues = false
            fetchRequest.predicate = predicate
            let sortDescriptors = sortDescriptorsKeys.compactMap { (key) -> NSSortDescriptor in
                return NSSortDescriptor(key: key, ascending: ascending)
            }
            fetchRequest.sortDescriptors = sortDescriptors
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }
    }

}
