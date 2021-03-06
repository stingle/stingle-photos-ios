//
//  STLibraryAlbumFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import Foundation

extension STLibrary {
    
    class AlbumFile: File {
        
        private enum CodingKeys: String, CodingKey {
            case albumId = "albumId"
        }
        
        let albumId: String
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.albumId = try container.decode(String.self, forKey: .albumId)
            try super.init(from: decoder)
        }
    }
    
}
