//
//  STLibraryAlbumFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import Foundation

extension STLibrary {
    
    class AlbumFile: File {
        
        typealias ManagedModel = STCDAlbumFile
        
        private enum CodingKeys: String, CodingKey {
            case albumId = "albumId"
        }
        
        let albumId: String
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.albumId = try container.decode(String.self, forKey: .albumId)
            try super.init(from: decoder)
        }
        
        required init(model: STCDAlbumFile) throws {
            guard let albumId = model.albumId else {
                throw LibraryError.parsError
            }
            self.albumId = albumId
            try super.init(file: model.file,
                           version: model.version,
                           headers: model.headers,
                           dateCreated: model.dateCreated,
                           dateModified: model.dateModified)
            
        }
        
        required init(model: STCDFile) throws {
            fatalError("init(model:) has not been implemented")
        }
 
        override func toManagedModelJson() throws -> [String : Any] {
            var json = try super.toManagedModelJson()
            json["albumId"] = self.albumId
            return json
        }
    }
    
}
