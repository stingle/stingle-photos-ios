//
//  STAlbumsProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumsProvider: DataBaseCollectionProvider<STLibrary.Album, STCDAlbum, STLibrary.DeleteFile.Album> {
        
        override func getInsertObjects(with albums: [STLibrary.Album]) throws -> (json: [[String : Any]], lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            
            try albums.forEach { (album) in
                let json = try album.toManagedModelJson()
                jsons.append(json)
                let currentLastDate = lastDate ?? album.dateModified
                if currentLastDate <= album.dateModified {
                    lastDate = album.dateModified
                }
            }
           
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            return (jsons, myLastDate)
        }
        
        override func getDeleteObjects(_ deleteFiles: [STLibrary.DeleteFile.Album], in context: NSManagedObjectContext) throws -> (models: [STCDAlbum], date: Date) {
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let context = self.container.newBackgroundContext()
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
        
        
    }

}
