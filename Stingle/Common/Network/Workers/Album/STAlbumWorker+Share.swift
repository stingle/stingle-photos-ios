//
//  SSTAlbumWorker+share.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/7/21.
//

import Foundation


extension STAlbumWorker {
    
    func shareAlbum(album: STLibrary.Album, contacts: [STContact], permitions: STLibrary.Album.Permission, reloadDBData: Bool = true, isHidden: Bool? = nil, isLocked: Bool? = nil, isRemote: Bool? = nil, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        let now = Date()
        guard let albumMetadata = album.albumMetadata else {
            failure?(WorkerError.emptyData)
            return
        }
        var sharingKeys = [String: String]()
        var members = [String]()
        
        if let userId = STApplication.shared.dataBase.userProvider.myUser?.userId {
            members.append(userId)
        }
        let crypto = STApplication.shared.crypto
        do {
            try contacts.forEach { contact in
                if let publicKey = contact.publicKey, let userPK = crypto.base64ToByte(encodedStr: publicKey) {
                   let albumSKForRecp = try crypto.encryptAlbumSK(albumSK: albumMetadata.privateKey, userPK: userPK)
                    if let albumSKForRecpToBase64 = crypto.bytesToBase64(data: albumSKForRecp) {
                        sharingKeys[contact.userId] = albumSKForRecpToBase64
                        members.append(contact.userId)
                    }
                }
            }
        } catch {
            failure?(WorkerError.error(error: error))
        }
       
        let membersStr = members.joined(separator: ",")
        let sharedAlbum = STLibrary.Album(albumId: album.albumId,
                                          encPrivateKey: album.encPrivateKey,
                                          publicKey: album.publicKey,
                                          metadata: album.metadata,
                                          isShared: true,
                                          isHidden: isHidden ?? album.isHidden,
                                          isOwner: album.isOwner,
                                          isLocked: isLocked ?? album.isLocked,
                                          isRemote: isRemote ?? true,
                                          permissions: permitions.stringValue,
                                          members: membersStr,
                                          cover: album.cover,
                                          dateCreated: album.dateCreated,
                                          dateModified: now,
                                          managedObjectID: album.managedObjectID)
                
        let request = STAlbumRequest.sharedAlbum(album: sharedAlbum, sharingKeys: sharingKeys)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.update(models: [sharedAlbum], reloadData: reloadDBData)
            success(response)
        }, failure: failure)
    }
    
    func createSharedAlbum(name: String, files: [STLibrary.GaleryFile], contacts: [STContact], permitions: STLibrary.Album.Permission, success: Success<STLibrary.Album>?, failure: Failure?) {
                        
        self.createAlbum(name: name, reloadDBData: true, success: { [weak self] album in
            self?.moveFiles(files: files, toAlbum: album, isMoving: false, success: { [weak self] _ in
                self?.shareAlbum(album: album, contacts: contacts, permitions: permitions, reloadDBData: true, isHidden: !files.isEmpty, success: { _ in
                    success?(album)
                }, failure: failure)
            }, failure: failure)
            
        }, failure: failure)
    }
    
    func createSharedAlbum(name: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], contacts: [STContact], permitions: STLibrary.Album.Permission, success: Success<STLibrary.Album>?, failure: Failure?) {
        
        let uploader = STApplication.shared.uploader
        
        files.forEach { albumFile in
            uploader.cancelUploadIng(for: albumFile)
        }
                        
        self.createAlbum(name: name, reloadDBData: true, success: { [weak self] album in
            self?.moveFiles(fromAlbum: fromAlbum, toAlbum: album, files: files, isMoving: false, reloadDBData: true, success: { [weak self] _ in
                self?.shareAlbum(album: album, contacts: contacts, permitions: permitions, reloadDBData: true, isHidden: !files.isEmpty, success: { _ in
                    success?(album)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
    }
    
    func resetAlbumMembers(album: STLibrary.Album, contacts: [STContact], success: Success<STEmptyResponse>?, failure: Failure?) {
        
        let now = Date()
        guard let albumMetadata = album.albumMetadata else {
            failure?(WorkerError.emptyData)
            return
        }
        var sharingKeys = [String: String]()
        var members = [String]()
        
        if let userId = STApplication.shared.dataBase.userProvider.myUser?.userId, !album.isOwner {
            members.append(userId)
        }
        let crypto = STApplication.shared.crypto
        do {
            try contacts.forEach { contact in
                if let publicKey = contact.publicKey, let userPK = crypto.base64ToByte(encodedStr: publicKey) {
                   let albumSKForRecp = try crypto.encryptAlbumSK(albumSK: albumMetadata.privateKey, userPK: userPK)
                    if let albumSKForRecpToBase64 = crypto.bytesToBase64(data: albumSKForRecp) {
                        sharingKeys[contact.userId] = albumSKForRecpToBase64
                        members.append(contact.userId)
                    }
                }
            }
        } catch {
            failure?(WorkerError.error(error: error))
        }
       
        let membersStr = members.joined(separator: ",")
        let sharedAlbum = STLibrary.Album(albumId: album.albumId,
                                          encPrivateKey: album.encPrivateKey,
                                          publicKey: album.publicKey,
                                          metadata: album.metadata,
                                          isShared: true,
                                          isHidden: album.isHidden,
                                          isOwner: album.isOwner,
                                          isLocked: album.isLocked,
                                          isRemote: album.isRemote,
                                          permissions: album.permissions,
                                          members: membersStr,
                                          cover: album.cover,
                                          dateCreated: album.dateCreated,
                                          dateModified: now,
                                          managedObjectID: album.managedObjectID)
        
        let request = STAlbumRequest.sharedAlbum(album: sharedAlbum, sharingKeys: sharingKeys)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.update(models: [sharedAlbum], reloadData: true)
            success?(response)
        }, failure: failure)
        
    }
    
    func leaveAlbum(album: STLibrary.Album, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        
        let request = STAlbumRequest.leaveAlbum(album: album)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
           
            let dataBase = STApplication.shared.dataBase
            let albumProvider = dataBase.albumsProvider
            let albumFilesProvider = dataBase.albumFilesProvider
            let files = albumFilesProvider.fetchAll(for: album.albumId)
            
            albumFilesProvider.delete(models: files, reloadData: true)
            albumProvider.delete(models: [album], reloadData: true)
            STApplication.shared.utils.deleteFilesIfNeeded(files: files, complition: nil)
            
            success(response)
        }, failure: failure)
        
    }
    
    func unshareAlbum(album: STLibrary.Album, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        let album = STLibrary.Album(albumId: album.albumId,
                                          encPrivateKey: album.encPrivateKey,
                                          publicKey: album.publicKey,
                                          metadata: album.metadata,
                                          isShared: false,
                                          isHidden: false,
                                          isOwner: album.isOwner,
                                          isLocked: album.isLocked,
                                          isRemote: album.isRemote,
                                          permissions: album.permissions,
                                          members: nil,
                                          cover: album.cover,
                                          dateCreated: album.dateCreated,
                                          dateModified: Date(),
                                          managedObjectID: album.managedObjectID)
        
        let request = STAlbumRequest.unshareAlbum(album: album)
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.update(models: [album], reloadData: true)
            success?(response)
        }, failure: failure)
        
    }
    
    func updatePermission(album: STLibrary.Album, permission: STLibrary.Album.Permission, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        let album = STLibrary.Album(albumId: album.albumId,
                                          encPrivateKey: album.encPrivateKey,
                                          publicKey: album.publicKey,
                                          metadata: album.metadata,
                                          isShared: album.isShared,
                                          isHidden: album.isHidden,
                                          isOwner: album.isOwner,
                                          isLocked: album.isLocked,
                                          isRemote: album.isRemote,
                                          permissions: permission.stringValue,
                                          members: album.members,
                                          cover: album.cover,
                                          dateCreated: album.dateCreated,
                                    dateModified: Date(),
                                    managedObjectID: album.managedObjectID)
        
        let request = STAlbumRequest.editPermsAlbum(album: album)
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.update(models: [album], reloadData: true)
            success?(response)
        }, failure: failure)
    }
    
}
