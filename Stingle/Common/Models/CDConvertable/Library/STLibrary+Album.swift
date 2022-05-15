//
//  STLibraryAlbum.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import CoreData

extension STLibrary {
    
    class Album: ICDSynchConvertable, Codable {
                                
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
        let managedObjectID: NSManagedObjectID?
        
        var identifier: String {
            return self.albumId
        }
        
        lazy var albumMetadata: AlbumMetadata? = {
            return try? STApplication.shared.crypto.decryptAlbum(albumPKStr: self.publicKey, encAlbumSKStr: self.encPrivateKey, metadataStr: self.metadata)
        }()
        
        lazy var permission: Permission = {
            let permissions = self.permissions
            let result = Permission(permissions: permissions, isOwner: self.isOwner)
            return result
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
            self.managedObjectID = nil
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
            self.managedObjectID = model.objectID
        }
        
        init(albumId: String, encPrivateKey: String, publicKey: String, metadata: String, isShared: Bool, isHidden: Bool, isOwner: Bool, isLocked: Bool, isRemote: Bool, permissions: String?, members: String?, cover: String?, dateCreated: Date, dateModified: Date, managedObjectID: NSManagedObjectID?) {
            self.albumId = albumId
            self.encPrivateKey = encPrivateKey
            self.publicKey = publicKey
            self.metadata = metadata
            self.isShared = isShared
            self.isHidden = isHidden
            self.isOwner = isOwner
            self.isLocked = isLocked
            self.isRemote = isRemote
            self.permissions = permissions
            self.members = members
            self.cover = cover
            self.dateCreated = dateCreated
            self.dateModified = dateModified
            self.managedObjectID = managedObjectID
        }

        init(album: STLibrary.Album, albumId: String? = nil, encPrivateKey: String? = nil, publicKey: String? = nil, metadata: String? = nil, isShared: Bool? = nil, isHidden: Bool? = nil, isOwner: Bool? = nil, isLocked: Bool? = nil, isRemote: Bool? = nil, permissions: String? = nil, members: String? = nil, cover: String? = nil, dateCreated: Date? = nil, dateModified: Date? = nil, managedObjectID: NSManagedObjectID? = nil) {
            self.albumId = albumId ?? album.albumId
            self.encPrivateKey = encPrivateKey ?? album.encPrivateKey
            self.publicKey = publicKey ?? album.publicKey
            self.metadata = metadata ?? album.metadata
            self.isShared = isShared ?? album.isShared
            self.isHidden = isHidden ?? album.isHidden
            self.isOwner = isOwner ?? album.isOwner
            self.isLocked = isLocked ?? album.isLocked
            self.isRemote = isRemote ?? album.isRemote
            self.permissions = permissions ?? album.permissions
            self.members = members ?? album.members
            self.cover = cover ?? album.cover
            self.dateCreated = dateCreated ?? album.dateCreated
            self.dateModified = dateModified ?? album.dateModified
            self.managedObjectID = managedObjectID ?? album.managedObjectID
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.albumId, forKey: .albumId)
            try container.encode(self.encPrivateKey, forKey: .encPrivateKey)
            try container.encode(self.publicKey, forKey: .publicKey)
            try container.encode(self.metadata, forKey: .metadata)
                                   
            try container.encode(self.permissions, forKey: .permissions)
            try container.encode(self.members, forKey: .members)
            try container.encode(self.cover, forKey: .cover)
            
            try container.encode(self.isShared ? "1": "0", forKey: .isShared)
            try container.encode(self.isHidden ? "1": "0", forKey: .isHidden)
            try container.encode(self.isOwner ? "1": "0", forKey: .isOwner)
            try container.encode(self.isLocked ? "1": "0", forKey: .isLocked)
            
            try container.encode("\(self.dateCreated.timeIntervalSince1970)", forKey: .dateCreated)
            try container.encode("\(self.dateModified.timeIntervalSince1970)", forKey: .dateModified)
        }
        
        //MARK: - ICDSynchConvertable
        
        func diffStatus(with rhs: STCDAlbum) -> STDataBase.ModelDiffStatus {
            guard self.identifier == rhs.identifier else { return .none }
            guard let dateModified = rhs.dateModified else { return .high }
            if dateModified == rhs.dateModified {
                return .equal
            }
            if dateModified < self.dateModified {
                return .high
            }
            return .low
        }
        
        func update(model: STCDAlbum) {
            model.albumId = self.albumId
            model.encPrivateKey = self.encPrivateKey
            model.publicKey = self.publicKey
            model.metadata = self.metadata
            model.isShared = self.isShared
            model.isHidden = self.isHidden
            model.isOwner = self.isOwner
            model.permissions = self.permissions
            model.members = self.members
            model.isLocked = self.isLocked
            model.cover = self.cover
            model.dateCreated = self.dateCreated
            model.dateModified = self.dateModified
            model.identifier = self.identifier
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
            json.addIfNeeded(key: "identifier", value: self.identifier)
            return json
        }
    }
    
}

extension STLibrary.Album {

    static func > (lhs: STLibrary.Album, rhs: STLibrary.Album) -> Bool {
        guard lhs.identifier == rhs.identifier else {
            return false
        }
        return lhs.dateModified > rhs.dateModified
    }
    
}

extension STLibrary.Album {
    
    static let imageBlankImageName = "__b__"
    
    struct Permission: Equatable {
        
        static let permissionVersion = 1;
        static let permissionLenght = 4;
        
        let allowAdd: Bool
        let allowShare: Bool
        let allowCopy: Bool
        
        init(permissions: String?, isOwner: Bool) {
            
            guard let permissions = permissions, permissions.count == Self.permissionLenght else {
                self.allowAdd = false
                self.allowShare = false
                self.allowCopy = false
                return
            }
                        
            guard String(permissions[0]) == "\(Self.permissionVersion)" else {
                self.allowAdd = false
                self.allowShare = false
                self.allowCopy = false
                return
            }
            self.allowAdd = String(permissions[1]) == "1"
            self.allowShare = String(permissions[2]) == "1"
            self.allowCopy = String(permissions[3]) == "1"
        }
        
        init(allowAdd: Bool, allowShare: Bool, allowCopy: Bool) {
            self.allowAdd = allowAdd
            self.allowShare = allowShare
            self.allowCopy = allowCopy
        }
        
        var stringValue: String {
            let allowAdd = self.allowAdd ? "1" : "0"
            let allowShare = self.allowShare ? "1" : "0"
            let allowCopy = self.allowCopy ? "1" : "0"
            return "\(Self.permissionVersion)" + allowAdd + allowShare + allowCopy
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.allowAdd == rhs.allowAdd && lhs.allowShare == rhs.allowShare && lhs.allowCopy == rhs.allowCopy
        }
        
    }
    
}
