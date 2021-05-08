//
//  STCreateAlbumWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/28/21.
//

import Foundation

class STAlbumWorker: STWorker {
    
    func createAlbum(name: String, reloadDBData: Bool = true, success: Success<STLibrary.Album>? = nil, failure: Failure?) {
        do {
            let encryptedAlbumData = try STApplication.shared.crypto.generateEncryptedAlbumDataAndID(albumName: name)
            self.createAlbum(encryptedAlbumData: encryptedAlbumData, reloadDBData: reloadDBData, success: success, failure: failure)
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
    
    
    func moveFiles(fromAlbum: STLibrary.Album, toAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isMoving: Bool, reloadDBData: Bool, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        let crypto = STApplication.shared.crypto
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        var newHeaders = [String: String]()
        
        do {
            let fromAlbumData = try crypto.decryptAlbum(albumPKStr: fromAlbum.publicKey, encAlbumSKStr: fromAlbum.encPrivateKey, metadataStr: fromAlbum.metadata)
            var newAlbumFiles = [STLibrary.AlbumFile]()
            for file in files {
                guard let publicKey = crypto.base64ToByte(encodedStr: toAlbum.publicKey) else {
                    failure?(WorkerError.emptyData)
                    return
                }
                let newHeader = try crypto.reencryptFileHeaders(headersStr: file.headers, publicKeyTo: publicKey, privateKeyFrom: fromAlbumData.privateKey, publicKeyFrom: fromAlbumData.publicKey)
                newHeaders[file.file] = newHeader
                
                let newAlbumFile = try STLibrary.AlbumFile(file: file.file,
                                                       version: file.version,
                                                       headers: newHeader,
                                                       dateCreated: file.dateCreated,
                                                       dateModified: Date(),
                                                       isRemote: file.isRemote,
                                                       albumId: toAlbum.albumId)
                newAlbumFiles.append(newAlbumFile)
            }
            
            let request = STAlbumRequest.moveFile(fromSet: .album, toSet: .album, albumIdFrom: fromAlbum.albumId, albumIdTo: toAlbum.albumId, isMoving: isMoving, headers: newHeaders, files: files)
            self.request(request: request, success: { (response: STEmptyResponse) in
                
                if isMoving {
                    albumFilesProvider.delete(models: files, reloadData: false)
                }
                
                let updatedAlbum = STLibrary.Album(albumId: toAlbum.albumId,
                                                   encPrivateKey: toAlbum.encPrivateKey,
                                                   publicKey: toAlbum.publicKey,
                                                   metadata: toAlbum.metadata,
                                                   isShared: toAlbum.isShared,
                                                   isHidden: toAlbum.isHidden,
                                                   isOwner: toAlbum.isOwner,
                                                   isLocked: toAlbum.isLocked,
                                                   isRemote: toAlbum.isRemote,
                                                   permissions: toAlbum.permissions,
                                                   members: toAlbum.members,
                                                   cover: toAlbum.cover,
                                                   dateCreated: toAlbum.dateCreated,
                                                   dateModified: Date())
                
                albumsProvider.update(models: [updatedAlbum], reloadData: reloadDBData)
                albumFilesProvider.add(models: newAlbumFiles, reloadData: reloadDBData)
                
                success?(response)
            }, failure: failure)
     
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
    
    private func createAlbum(encryptedAlbumData: (encPrivateKey: String, publicKey: String, metadata: String, albumID: String), reloadDBData: Bool, success: Success<STLibrary.Album>? = nil, failure: Failure?) {
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
            STApplication.shared.dataBase.albumsProvider.add(models: [album], reloadData: reloadDBData)
            success?(album)
        } failure: { (error) in
            failure?(error)
        }
    }
    
    
}

