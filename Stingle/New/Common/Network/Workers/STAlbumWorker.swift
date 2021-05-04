//
//  STCreateAlbumWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/28/21.
//

import Foundation

class STAlbumWorker: STWorker {
    
    func createAlbum(name: String, success: Success<STLibrary.Album>? = nil, failure: Failure?) {
        do {
            let encryptedAlbumData = try STApplication.shared.crypto.generateEncryptedAlbumDataAndID(albumName: name)
            self.createAlbum(encryptedAlbumData: encryptedAlbumData, success: success, failure: failure)
        } catch {
            failure?(WorkerError.error(error: error))
        }
    }
    
    func deleteAlbumWithFiles(album: STLibrary.Album, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        let files = STApplication.shared.dataBase.albumFilesProvider.fetchAll(for: album.albumId)
        
        self.deleteAlbumFiles(album: album, files: files, success: { [weak self] responce in
            self?.deleteAlbum(album: album, success: success, failure: failure)
        }, failure: failure)
    }
    
    func deleteAlbum(album: STLibrary.Album, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        let request = STAlbumRequest.deleteAlbum(albumID: album.albumId)
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.delete(models: [album], reloadData: true)
            success(response)
        }, failure: failure)
    }
    
    func deleteAlbumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile], success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        
        guard !files.isEmpty else {
            success(STEmptyResponse())
            return
        }
        
        let crypto = STApplication.shared.crypto
        let uploader = STApplication.shared.uploader
        do {
            let publicKey = try crypto.readPublicKey()
            let metadata = try STApplication.shared.crypto.decryptAlbum(albumPKStr: album.publicKey, encAlbumSKStr: album.encPrivateKey, metadataStr: album.metadata)
            var headers = [String: String]()
            
            var trahFiles = [STLibrary.TrashFile]()
                        
            for file in files {
                let newHeader = try crypto.reencryptFileHeaders(headersStr: file.headers, publicKeyTo: publicKey, privateKeyFrom: metadata.privateKey, publicKeyFrom: metadata.publicKey);
                headers[file.file] = newHeader
                uploader.cancelUploadIng(for: file)
                
                if let trashFile = try? STLibrary.TrashFile(file: file.file, version: file.version, headers: newHeader, dateCreated: file.dateCreated, dateModified: file.dateModified, isRemote: file.isRemote) {
                    trahFiles.append(trashFile)
                }
            }
            let request = STAlbumRequest.moveFile(fromSet: .album, toSet: .trash, albumIdFrom: album.albumId, albumIdTo: nil, isMoving: true, headers: headers, files: files)
            self.request(request: request) { (response: STEmptyResponse) in
                
                let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
                let trashProvider = STApplication.shared.dataBase.trashProvider
                
                albumFilesProvider.delete(models: files, reloadData: true)
                trashProvider.add(models: trahFiles, reloadData: true)
                
                success(response)
            } failure: { (error) in
                failure?(error)
            }
        } catch {
            failure?(WorkerError.error(error: error))
        }
    }
    
    func shareAlbum(album: STLibrary.Album, contacts: [STContact], permitions: STLibrary.Album.Permission, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
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
                                          isHidden: album.isHidden,
                                          isOwner: album.isOwner,
                                          isLocked: album.isLocked, isRemote: true,
                                          permissions: permitions.stringValue,
                                          members: membersStr,
                                          cover: album.cover,
                                          dateCreated: album.dateCreated,
                                          dateModified: now)
                
        let request = STAlbumRequest.sharedAlbum(album: sharedAlbum, sharingKeys: sharingKeys)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            albumFilesProvider.update(models: [sharedAlbum], reloadData: true)
            success(response)
        }, failure: failure)
  
    }
    
   //MARK: - Private
    
    private func createAlbum(encryptedAlbumData: (encPrivateKey: String, publicKey: String, metadata: String, albumID: String), success: Success<STLibrary.Album>? = nil, failure: Failure?) {
        let now = Date()
        let album = STLibrary.Album(albumId: encryptedAlbumData.albumID,
                                    encPrivateKey: encryptedAlbumData.encPrivateKey,
                                    publicKey: encryptedAlbumData.publicKey,
                                    metadata: encryptedAlbumData.metadata,
                                    isShared: false,
                                    isHidden: false,
                                    isOwner: true,
                                    isLocked: false,
                                    isRemote: true,
                                    permissions: nil,
                                    members: nil,
                                    cover: nil,
                                    dateCreated: now,
                                    dateModified: now)
                
        let request = STAlbumRequest.create(album: album)
        self.request(request: request) { (response: STEmptyResponse) in
            STApplication.shared.dataBase.albumsProvider.add(models: [album], reloadData: true)
            success?(album)
        } failure: { (error) in
            failure?(error)
        }
    }
    
    
}

