//
//  STAlbumsProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumsProvider: DataBaseProvider<STLibrary.Album, STCDAlbum> {
  
        override func newBatchInsertRequest(with albums: [STLibrary.Album], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
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
            
            let insertRequest = NSBatchInsertRequest(entity: STCDAlbum.entity(), objects: jsons)
            insertRequest.resultType = .statusOnly
            return (insertRequest, myLastDate)
        }
        
    }

}
