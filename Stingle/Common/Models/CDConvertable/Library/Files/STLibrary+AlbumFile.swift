//
//  STLibraryAlbumFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import CoreData

extension STLibrary {
    
    class AlbumFile: File<STCDAlbumFile> {
                
        private enum CodingKeys: String, CodingKey {
            case albumId = "albumId"
        }
        
        let albumId: String
        
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
                           isRemote: model.isRemote,
                           isSynched: model.isSynched,
                           managedObjectID: model.objectID)
            
        }
        
        init(file: String, version: String, headers: String, dateCreated: Date, dateModified: Date, isRemote: Bool, isSynched: Bool, albumId: String, managedObjectID: NSManagedObjectID?) {
            self.albumId = albumId
            super.init(fileName: file,
                       version: version,
                       headers: headers,
                       dateCreated: dateCreated,
                       dateModified: dateModified,
                       isRemote: isRemote,
                       isSynched: isSynched,
                       managedObjectID: managedObjectID)
          
        }
        
        init(file: String?, version: String?, headers: String?, dateCreated: Date?, dateModified: Date?, isRemote: Bool,  isSynched: Bool?, albumId: String, managedObjectID: NSManagedObjectID?) throws {
            self.albumId = albumId
            try super.init(file: file, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, managedObjectID: managedObjectID)
        }
        
        override func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil, managedObjectID: NSManagedObjectID? = nil) -> Self {
            
            let fileName = fileName ?? self.file
            let version = version ?? self.version
            let headers = headers ?? self.headers
            let dateCreated = dateCreated ?? self.dateCreated
            let dateModified = dateModified ?? self.dateModified
            let isRemote = isRemote ?? self.isRemote
            let managedObjectID = managedObjectID ?? self.managedObjectID
            let isSynched = isSynched ?? self.isSynched
            
            return AlbumFile(file: fileName,
                             version: version,
                             headers: headers,
                             dateCreated: dateCreated,
                             dateModified: dateModified,
                             isRemote: isRemote,
                             isSynched: isSynched,
                             albumId: self.albumId,
                             managedObjectID: managedObjectID) as! Self
            
        }
        
        override func diffStatus(with rhs: STCDAlbumFile) -> STDataBase.ModelModifyStatus {
            guard self.albumId != rhs.albumId else { return .none }
            return super.diffStatus(with: rhs)
        }
        
        override func toManagedModelJson() throws -> [String : Any] {
            var json = try super.toManagedModelJson()
            json["albumId"] = self.albumId
            return json
        }
        
        override func update(model: STCDAlbumFile) {
            super.update(model: model)
            model.albumId = self.albumId
        }
        
        override func getImageParameters(isThumb: Bool) -> [String : String] {
            var params = super.getImageParameters(isThumb: isThumb)
            params["albumId"] = "\(self.albumId)"
            return params
        }
        
        override func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil) -> Self {
            return self.copy(fileName: fileName, version: version, headers: headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: isRemote, isSynched: isSynched, albumID: self.albumId, managedObjectID: self.managedObjectID)
        }
        
        func copy(fileName: String? = nil, version: String? = nil, headers: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, isRemote: Bool? = nil, isSynched: Bool? = nil, albumID: String? = nil, managedObjectID: NSManagedObjectID? = nil) -> Self {
            
            let fileName = fileName ?? self.file
            let version = version ?? self.version
            let headers = headers ?? self.headers
            let dateCreated = dateCreated ?? self.dateCreated
            let dateModified = dateModified ?? self.dateModified
            let isRemote = isRemote ?? self.isRemote
            let managedObjectID = managedObjectID ?? self.managedObjectID
            let albumId = albumID ?? self.albumId
            let isSynched = isSynched ?? self.isSynched
            
            return AlbumFile(file: fileName,
                             version: version,
                             headers: headers,
                             dateCreated: dateCreated,
                             dateModified: dateModified,
                             isRemote: isRemote,
                             isSynched: isSynched,
                             albumId: albumId,
                             managedObjectID: managedObjectID) as! Self
            
        }
                
        func updateIfNeeded(albumMetadata: Album.AlbumMetadata?) {
            guard albumMetadata != self.albumMetadata else {
                return
            }
            if let albumMetadata = albumMetadata {
                self.albumMetadata = albumMetadata
                self.decryptsHeaders = STApplication.shared.crypto.getHeaders(headersStrs: self.headers, publicKey: albumMetadata.publicKey, privateKey: albumMetadata.privateKey)
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
