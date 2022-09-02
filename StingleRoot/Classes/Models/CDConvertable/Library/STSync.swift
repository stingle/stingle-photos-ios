//
//  STSync.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import Foundation

class STSync: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case spaceUsed = "spaceUsed"
        case spaceQuota = "spaceQuota"
        case galery = "files"
        case albums = "albums"
        case albumFiles = "albumFiles"
        case trash = "trash"
        case deletes = "deletes"
        case contacts = "contacts"
    }
        
    let spaceUsed: String
    let spaceQuota: String
    
    let galery: [STLibrary.GaleryFile]?
    let albums: [STLibrary.Album]?
    let albumFiles: [STLibrary.AlbumFile]?
    let trash: [STLibrary.TrashFile]?
    let deletes: STLibrary.DeleteFile?
    let contacts: [STContact]?
            
}
