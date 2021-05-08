//
//  STCDAlbum+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDAlbum)
public class STCDAlbum: NSManagedObject, IManagedObject {

    func update(model: STLibrary.Album, context: NSManagedObjectContext) {
        self.albumId = model.albumId
        self.encPrivateKey = model.encPrivateKey
        self.publicKey = model.publicKey
        self.metadata = model.metadata
        self.isShared = model.isShared
        self.isHidden = model.isHidden
        self.isOwner = model.isOwner
        self.permissions = model.permissions
        self.members = model.members
        self.isLocked = model.isLocked
        self.cover = model.cover
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STLibrary.Album {
        return try STLibrary.Album(model: self)
    }

}
