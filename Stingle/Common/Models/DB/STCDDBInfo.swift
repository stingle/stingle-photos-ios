//
//  STCDDBInfo+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/10/21.
//
//

import Foundation
import CoreData

@objc(STCDDBInfo)
public class STCDDBInfo: NSManagedObject {
    
}

extension STCDDBInfo: IManagedObject {
    
    func update(model: STDBInfo) {
        self.lastSeenTime = model.lastSeenTime
        self.lastTrashSeenTime = model.lastTrashSeenTime
        self.lastAlbumsSeenTime = model.lastAlbumsSeenTime
        self.lastAlbumFilesSeenTime = model.lastAlbumFilesSeenTime
        self.lastDelSeenTime = model.lastDelSeenTime
        self.lastContactsSeenTime = model.lastContactsSeenTime
        self.spaceUsed = model.spaceUsed
        self.spaceQuota = model.spaceQuota
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STDBInfo {
        return STDBInfo(lastSeenTime: self.lastSeenTime, lastTrashSeenTime: self.lastTrashSeenTime, lastAlbumsSeenTime: self.lastAlbumsSeenTime, lastAlbumFilesSeenTime: self.lastAlbumFilesSeenTime, lastDelSeenTime: self.lastDelSeenTime, lastContactsSeenTime: self.lastContactsSeenTime, spaceUsed: self.spaceUsed, spaceQuota: self.spaceQuota, managedObjectID: self.objectID)
    }
    
}


