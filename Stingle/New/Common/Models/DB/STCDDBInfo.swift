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
public class STCDDBInfo: NSManagedObject, IManagedObject {
        
    func update(model: STDBInfo, context: NSManagedObjectContext) {
        self.lastSeenTime = model.lastSeenTime
        self.lastTrashSeenTime = model.lastTrashSeenTime
        self.lastAlbumsSeenTime = model.lastAlbumsSeenTime
        self.lastAlbumFilesSeenTime = model.lastAlbumFilesSeenTime
        self.lastDelSeenTime = model.lastDelSeenTime
        self.lastContactsSeenTime = model.lastContactsSeenTime
        self.spaceUsed = model.spaceUsed
        self.spaceQuota = model.spaceQuota
    }

}
