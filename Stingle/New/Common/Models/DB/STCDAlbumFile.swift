//
//  STCDAlbumFile+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDAlbumFile)
public class STCDAlbumFile: NSManagedObject, IManagedObject {

    func update(model: STLibrary.AlbumFile, context: NSManagedObjectContext?) {
        self.file = model.file
        self.version = model.version
        self.headers = model.headers
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.albumId = model.albumId
        self.isRemote = model.isRemote
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STLibrary.AlbumFile {
        return try STLibrary.AlbumFile(model: self)
    }
    
}
