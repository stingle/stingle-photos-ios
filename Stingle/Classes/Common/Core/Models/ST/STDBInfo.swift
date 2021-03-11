//
//  STDBInfo.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/21.
//

import Foundation

class STDBInfo: ICDConvertable {
        
    private enum CodingKeys: String, CodingKey {
        case lastSeenTime = "filesST"
        case lastTrashSeenTime = "trashST"
        case lastAlbumsSeenTime = "albumsST"
        case lastAlbumFilesSeenTime = "albumFilesST"
        case lastDelSeenTime = "delST"
        case lastContactsSeenTime = "cntST"
    }
            
    private(set) var lastSeenTime: Date?
    private(set) var lastTrashSeenTime: Date?
    private(set) var lastAlbumsSeenTime: Date?
    private(set) var lastAlbumFilesSeenTime: Date?
    private(set) var lastDelSeenTime: Date?
    private(set) var lastContactsSeenTime: Date?
    
    required convenience init(model: STCDDBInfo) throws {
        self.init()
        self.lastSeenTime = model.lastSeenTime
        self.lastTrashSeenTime = model.lastTrashSeenTime
        self.lastAlbumsSeenTime = model.lastAlbumsSeenTime
        self.lastAlbumFilesSeenTime = model.lastAlbumFilesSeenTime
        self.lastDelSeenTime = model.lastDelSeenTime
        self.lastContactsSeenTime = model.lastContactsSeenTime
    }

}
