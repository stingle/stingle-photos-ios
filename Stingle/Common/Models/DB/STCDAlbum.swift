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
public class STCDAlbum: NSManagedObject {

}

extension STCDAlbum: IManagedSynchObject {
    
    func update(model: STLibrary.Album) {
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
    
    func mastUpdate(with model: STLibrary.Album) -> Bool {
        guard self.identifier == model.identifier else {
            return false
        }
        guard let dateModified = self.dateModified else {
            return true
        }
        return dateModified < model.dateModified
    }
    
}
