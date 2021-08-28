//
//  STDBInfo.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/21.
//

import CoreData

class STDBInfo: ICDConvertable {
        
    private enum CodingKeys: String, CodingKey {
        case lastSeenTime = "filesST"
        case lastTrashSeenTime = "trashST"
        case lastAlbumsSeenTime = "albumsST"
        case lastAlbumFilesSeenTime = "albumFilesST"
        case lastDelSeenTime = "delST"
        case lastContactsSeenTime = "cntST"
    }
            
    var lastSeenTime: Date
    var lastTrashSeenTime: Date
    var lastAlbumsSeenTime: Date
    var lastAlbumFilesSeenTime: Date
    var lastDelSeenTime: Date
    var lastContactsSeenTime: Date
    var managedObjectID: NSManagedObjectID?
    
    var spaceUsed: String?
    var spaceQuota: String?
    
    var identifier: String {
        return ""
    }
       
    init(lastSeenTime: Date? = nil, lastTrashSeenTime: Date? = nil, lastAlbumsSeenTime: Date? = nil, lastAlbumFilesSeenTime: Date? = nil, lastDelSeenTime: Date? = nil, lastContactsSeenTime: Date? = nil, spaceUsed: String? = nil, spaceQuota: String? = nil, managedObjectID: NSManagedObjectID? = nil) {
        let defaultDate = Date.defaultDate
        self.lastSeenTime = lastSeenTime ?? defaultDate
        self.lastTrashSeenTime = lastTrashSeenTime ?? defaultDate
        self.lastAlbumsSeenTime = lastAlbumsSeenTime ?? defaultDate
        self.lastAlbumFilesSeenTime = lastAlbumFilesSeenTime ?? defaultDate
        self.lastDelSeenTime = lastDelSeenTime ?? defaultDate
        self.lastContactsSeenTime = lastContactsSeenTime ?? defaultDate
        self.spaceUsed = spaceUsed
        self.spaceQuota = spaceQuota
        self.managedObjectID = managedObjectID
    }
    
    required convenience init(model: STCDDBInfo) throws {
        self.init(lastSeenTime: model.lastSeenTime,
                  lastTrashSeenTime: model.lastTrashSeenTime,
                  lastAlbumsSeenTime: model.lastAlbumsSeenTime,
                  lastAlbumFilesSeenTime: model.lastAlbumFilesSeenTime,
                  lastDelSeenTime: model.lastDelSeenTime,
                  lastContactsSeenTime: model.lastContactsSeenTime,
                  spaceUsed: model.spaceUsed,
                  spaceQuota: model.spaceQuota,
                  managedObjectID: model.objectID)
    }
    
    func update(with used: STDBUsed) {
        self.spaceUsed = "\(used.spaceUsed)"
        self.spaceQuota = used.spaceQuota
    }

}


extension STDBInfo {
    
    var lastSeenTimeSeccounds: UInt64 {
        return self.lastSeenTime.millisecondsSince1970
    }
    
    var lastTrashSeenTimeSeccounds: UInt64 {
        return self.lastTrashSeenTime.millisecondsSince1970
    }
    
    var lastAlbumsSeenTimeSeccounds: UInt64 {
        return self.lastAlbumsSeenTime.millisecondsSince1970
    }
    
    var lastAlbumFilesSeenTimeSeccounds: UInt64 {
        return self.lastAlbumFilesSeenTime.millisecondsSince1970
    }
    
    var lastDelSeenTimeSeccounds: UInt64 {
        return self.lastDelSeenTime.millisecondsSince1970
    }
    
    var lastContactsSeenTimeSeccounds: UInt64 {
        return self.lastContactsSeenTime.millisecondsSince1970
    }
    
}
