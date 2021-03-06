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
        case files = "files"
        case albums = "albums"
        case albumFiles = "albumFiles"
        case trash = "trash"
        case deletes = "deletes"
    }
        
    let spaceUsed: String
    let spaceQuota: String
    
    let files: [STLibrary.File]?
    let albums: [STLibrary.Album]?
    let albumFiles: [STLibrary.AlbumFile]?
    let trash: [STLibrary.TrashFile]?
    let deletes: [STLibrary.DeleteFile]?
        
}
