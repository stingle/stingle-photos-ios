//
//  STTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import Foundation


extension STLibrary {
        
    class TrashFile: Decodable {
        
        private enum CodingKeys: String, CodingKey {
            case albumId = "albumId"
        }
        
        let file: File
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let albumId = try container.decodeIfPresent(String.self, forKey: .albumId)
            
            if albumId == nil {
                self.file = try File.init(from: decoder)
            } else {
                self.file = try AlbumFile.init(from: decoder)
            }
        }
    }
    
}



