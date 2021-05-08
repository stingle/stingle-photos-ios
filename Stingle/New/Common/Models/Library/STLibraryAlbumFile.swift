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
        
        var albumId: String
        
        override var dbSet: DBSet {
            return .album
        }
        
        override var identifier: String {
            return Self.createIdentifier(albumId: self.albumId, fileName: self.file)
        }
        
        private(set) var albumMetadata: Album.AlbumMetadata?
        
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
                           dateModified: model.dateModified,
                           isRemote: model.isRemote)
            
        }
        
        required init(model: STCDFile) throws {
            fatalError("init(model:) has not been implemented")
        }
        
        init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool, albumId: String) throws {
            self.albumId = albumId
            try super.init(file: file, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote)
        }
        
        override func toManagedModelJson() throws -> [String : Any] {
            var json = try super.toManagedModelJson()
            json["albumId"] = self.albumId
            return json
        }
        
        func updateIfNeeded(albumMetadata: Album.AlbumMetadata?) {
            guard albumMetadata != self.albumMetadata else {
                return
            }
            if let albumMetadata = albumMetadata {
                self.albumMetadata = albumMetadata
                self.decryptsHeaders = STApplication.shared.crypto.getHeaders(file: self, publicKey: albumMetadata.publicKey, privateKey: albumMetadata.privateKey)
            } else {
                self.decryptsHeaders.thumb = nil
                self.decryptsHeaders.file = nil
            }
            
        }
        
    }
    
}


extension STLibrary.AlbumFile {
    
    class func createIdentifier(albumId: String, fileName: String) -> String {
        return fileName + "_" + albumId
    }
    
}
