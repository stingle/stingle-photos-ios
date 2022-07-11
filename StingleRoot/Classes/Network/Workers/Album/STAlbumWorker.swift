//
//  STCreateAlbumWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/28/21.
//

import Foundation

public class STAlbumWorker: STWorker {
    
    public func setCover(album: STLibrary.Album, caver: String?, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        
        let request = STAlbumRequest.setCover(album: album, caver: caver)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
            
            let album = STLibrary.Album(albumId: album.albumId,
                                        encPrivateKey: album.encPrivateKey,
                                        publicKey: album.publicKey,
                                        metadata: album.metadata,
                                        isShared: album.isShared,
                                        isHidden: album.isHidden,
                                        isOwner: album.isOwner,
                                        isLocked: album.isLocked,
                                        isRemote: album.isRemote,
                                        permissions: album.permissions,
                                        members: album.members,
                                        cover: caver,
                                        dateCreated: album.dateCreated,
                                        dateModified: Date(),
                                        managedObjectID: album.managedObjectID)
            
            albumFilesProvider.update(models: [album], reloadData: true)
            success(response)
        }, failure: failure)
        
    }
    
    public func rename(album: STLibrary.Album, name: String?, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        
        let name = name ?? ""
        
        let crypto = STApplication.shared.crypto
        do {
            
            let metadata = try STApplication.shared.crypto.decryptAlbum(albumPKStr: album.publicKey, encAlbumSKStr: album.encPrivateKey, metadataStr: album.metadata)
            let metadataBytes = try crypto.encryptAlbumMetadata(albumPK: metadata.publicKey, albumName: name)
            guard let newMetadata = crypto.bytesToBase64(data: metadataBytes) else {
                failure?(WorkerError.unknown)
                return
            }
            let request = STAlbumRequest.rename(album: album, metadata: newMetadata)
            
            self.request(request: request, success: { (response: STEmptyResponse) in
                let albumProvider = STApplication.shared.dataBase.albumsProvider
                let newAlbum = STLibrary.Album(albumId: album.albumId,
                                            encPrivateKey: album.encPrivateKey,
                                            publicKey: album.publicKey,
                                            metadata: newMetadata,
                                            isShared: album.isShared,
                                            isHidden: album.isHidden,
                                            isOwner: album.isOwner,
                                            isLocked: album.isLocked,
                                            isRemote: album.isRemote,
                                            permissions: album.permissions,
                                            members: album.members,
                                            cover: album.cover,
                                            dateCreated: album.dateCreated,
                                               dateModified: Date(),
                                               managedObjectID: album.managedObjectID)
                
                albumProvider.update(models: [newAlbum], reloadData: true)
                success(response)
            }, failure: failure)
            
        } catch {
            failure?(WorkerError.error(error: error))
        }
        
    }
                
    public func deleteAlbumWithFiles(album: STLibrary.Album, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        let files = STApplication.shared.dataBase.albumFilesProvider.fetchObjects(albumID: album.albumId)
        self.deleteAlbumFiles(album: album, files: files, success: { [weak self] responce in
            self?.deleteAlbum(album: album, success: success, failure: failure)
        }, failure: failure)
    }
     
    public func deleteAlbumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile], success: @escaping Success<STEmptyResponse>, failure: Failure?) {
        
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
                
                STApplication.shared.uploader.cancelUploadIng(for: file)
                
                let newHeader = try crypto.reencryptFileHeaders(headersStr: file.headers, publicKeyTo: publicKey, privateKeyFrom: metadata.privateKey, publicKeyFrom: metadata.publicKey);
                headers[file.file] = newHeader
                uploader.cancelUploadIng(for: file)
                
                if let trashFile = try? STLibrary.TrashFile(file: file.file, version: file.version, headers: newHeader, dateCreated: file.dateCreated, dateModified: file.dateModified, isRemote: file.isRemote, isSynched: file.isSynched, managedObjectID: nil) {
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
        
   //MARK: - Private
    
    private func deleteAlbum(album: STLibrary.Album, success: @escaping Success<STEmptyResponse>, failure: Failure?) {
       let request = STAlbumRequest.deleteAlbum(albumID: album.albumId)
       self.request(request: request, success: { (response: STEmptyResponse) in
           let albumFilesProvider = STApplication.shared.dataBase.albumsProvider
           albumFilesProvider.delete(models: [album], reloadData: true)
           success(response)
       }, failure: failure)
   }
    
}
