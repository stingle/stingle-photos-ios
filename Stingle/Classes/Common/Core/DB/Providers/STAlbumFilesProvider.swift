//
//  STAlbumFilesProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumFilesProvider: DataBaseProvider<STLibrary.AlbumFile, STCDAlbumFile> {
        
        override func newBatchInsertRequest(with albumFiles: [STLibrary.AlbumFile], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            
            try albumFiles.forEach { (albumFile) in
                let json = try albumFile.toManagedModelJson()
                jsons.append(json)
                let currentLastDate = lastDate ?? albumFile.dateModified
                if currentLastDate <= albumFile.dateModified {
                    lastDate = albumFile.dateModified
                }
            }
            
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let insertRequest = NSBatchInsertRequest(entity: STCDAlbumFile.entity(), objects: jsons)
            insertRequest.resultType = .statusOnly
            return (insertRequest, myLastDate)
        }
        
    }

}
