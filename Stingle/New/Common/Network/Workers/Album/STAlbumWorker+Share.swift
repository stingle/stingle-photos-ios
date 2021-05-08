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
                                          dateModified: now)
                
        let request = STAlbumRequest.sharedAlbum(album: sharedAlbum, sharingKeys: sharingKeys)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.update(models: [sharedAlbum], reloadData: reloadDBData)
            success(response)
        }, failure: failure)
    }
    
    func createSharedAlbum(name: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], contacts: [STContact], permitions: STLibrary.Album.Permission, success: Success<STLibrary.Album>?, failure: Failure?) {
        
        guard files.first(where: {$0.isRemote == false}) == nil else {
            failure?(WorkerError.unknown)
            return
        }
                        
        self.createAlbum(name: name, reloadDBData: true, success: { [weak self] album in
            self?.moveFiles(fromAlbum: fromAlbum, toAlbum: album, files: files, isMoving: false, reloadDBData: true, success: { [weak self] _ in
                self?.shareAlbum(album: album, contacts: contacts, permitions: permitions, reloadDBData: true, isHidden: !files.isEmpty, success: { _ in
                    success?(album)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
    }
    
}
