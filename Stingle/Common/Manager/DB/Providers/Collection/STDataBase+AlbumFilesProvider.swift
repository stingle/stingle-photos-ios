//
//  STAlbumFilesProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumFilesProvider: SyncProvider<STLibrary.AlbumFile, STLibrary.DeleteFile.AlbumFile> {
        
        override var providerType: SyncProviderType {
            return .albumFiles
        }
        
        
        //MARK: - public
        
        func fetch(for albumID: String, fileNames: [String]? = nil, sortDescriptorsKeys: [String], ascending: Bool) -> [STCDAlbumFile] {
            
            var predicate: NSPredicate!
            if let fileNames = fileNames {
                predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@ && \(#keyPath(STCDAlbumFile.file)) IN %@", albumID, fileNames)
            } else {
                predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
            }
            let context = self.container.viewContext
            return context.performAndWait { () -> [STCDAlbumFile] in
                let fetchRequest = NSFetchRequest<STCDAlbumFile>(entityName: STCDAlbumFile.entityName)
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
        
        func fetchObjects(for albumID: String) -> [STCDAlbumFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
            let result = self.fetch(predicate: predicate)
            return result
        }
        
        func fetchAll(for albumID: String) -> [STLibrary.AlbumFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
            let result = self.fetchObjects(predicate: predicate)
            return result
        }
        
        func fetchAll(for albumID: String, fileNames: [String]) -> [STLibrary.AlbumFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@ && \(#keyPath(STCDAlbumFile.identifier)) IN %@", albumID, fileNames)
            let result = self.fetchObjects(predicate: predicate)
            return result
        }
        
        func fetchAll(for albumID: String, identifiers: [String]) -> [STLibrary.AlbumFile] {
            let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@ && \(#keyPath(STCDAlbumFile.identifier)) IN %@", albumID, identifiers)
            let result = self.fetchObjects(predicate: predicate)
            return result
        }
        
    }
}

