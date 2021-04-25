//
//  STLibraryAlbum.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import Foundation

extension STLibrary {
    
    class Album: ICDConvertable, Codable {
                
        private enum CodingKeys: String, CodingKey {
            case albumId = "albumId"
            case encPrivateKey = "encPrivateKey"
            case publicKey = "publicKey"
            case metadata = "metadata"
            case isShared = "isShared"
            case isHidden = "isHidden"
            case isOwner = "isOwner"
            case permissions = "permissions"
            case members = "members"
            case isLocked = "isLocked"
            case cover = "cover"
            case dateCreated = "dateCreated"
            case dateModified = "dateModified"
        }
        
        let albumId: String
        let encPrivateKey: String
        let publicKey: String
        let metadata: String
        let isShared: Bool
        let isHidden: Bool
        let isOwner: Bool
        let permissions: String?
        let members: String?
        let isLocked: Bool
        let cover: String?
        let dateCreated: Date
        let dateModified: Date
        let isRemote: Bool
        
        var identifier: String {
            return self.albumId
        }
        
        lazy var albumMetadata: AlbumMetadata? = {
            return try? STApplication.shared.crypto.decryptAlbum(albumPKStr: self.publicKey, encAlbumSKStr: self.encPrivateKey, metadataStr: self.metadata)
        }()
                
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.albumId = try container.decode(String.self, forKey: .albumId)
            self.encPrivateKey = try container.decode(String.self, forKey: .encPrivateKey)
            self.publicKey = try container.decode(String.self, forKey: .publicKey)
            self.metadata = try container.decode(String.self, forKey: .metadata)
            self.permissions = try container.decodeIfPresent(String.self, forKey: .permissions)
            self.members = try container.decodeIfPresent(String.self, forKey: .members)
            self.cover = try container.decodeIfPresent(String.self, forKey: .cover)
                        
            self.isShared = (try container.decode(String.self, forKey: .isShared) == "1") ? true : false
            self.isHidden = (try container.decode(String.self, forKey: .isHidden) == "1") ? true : false
            self.isOwner = (try container.decode(String.self, forKey: .isOwner) == "1") ? true : false
            self.isLocked = (try container.decode(String.self, forKey: .isLocked) == "1") ? true : false
            self.isRemote = true
            
            let dateCreatedStr = try container.decode(String.self, forKey: .dateCreated)
            let dateModifiedStr = try container.decode(String.self, forKey: .dateModified)
            guard let dateCreated = UInt64(dateCreatedStr), let dateModified = UInt64(dateModifiedStr) else {
                throw LibraryError.parsError
            }
            self.dateCreated = Date(milliseconds: dateCreated)
            self.dateModified = Date(milliseconds: dateModified)
        }
        
        required init(model: STCDAlbum) throws {
            
            guard let albumId = model.albumId,
                  let encPrivateKey = model.encPrivateKey,
                  let publicKey = model.publicKey,
                  let metadata = model.metadata,
                  let dateCreated = model.dateCreated,
                  let dateModified = model.dateModified else {
                throw LibraryError.parsError
            }
            
            self.albumId = albumId
            self.encPrivateKey = encPrivateKey
            self.publicKey = publicKey
            self.metadata = metadata
            self.isShared = model.isShared
            self.isHidden = model.isHidden
            self.isOwner = model.isOwner
            self.permissions = model.permissions
            
            self.members = model.members
            self.isLocked = model.isLocked
            self.cover = model.cover
            self.isRemote = model.isRemote
            
            self.dateCreated = dateCreated
            self.dateModified = dateModified
        }
        
        func toManagedModelJson() throws -> [String : Any] {
            var json = [String : Any]()
            json.addIfNeeded(key: "albumId", value: self.albumId)
            json.addIfNeeded(key: "encPrivateKey", value: self.encPrivateKey)
            json.addIfNeeded(key: "publicKey", value: self.publicKey)
            json.addIfNeeded(key: "metadata", value: self.metadata)
            json.addIfNeeded(key: "isShared", value: self.isShared)
            json.addIfNeeded(key: "isHidden", value: self.isHidden)
            json.addIfNeeded(key: "isOwner", value: self.isOwner)
            json.addIfNeeded(key: "permissions", value: self.permissions)
            json.addIfNeeded(key: "members", value: self.members)
            json.addIfNeeded(key: "isLocked", value: self.isLocked)
            json.addIfNeeded(key: "cover", value: self.cover)
            json.addIfNeeded(key: "dateCreated", value: self.dateCreated)
            json.addIfNeeded(key: "dateModified", value: self.dateModified)
            json.addIfNeeded(key: "isRemote", value: self.isRemote)
            return json
        }
   
    }
    
}



