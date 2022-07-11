//
//  STAlbumWorker+Move.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/9/21.
//

import Foundation

public extension STAlbumWorker {
    
    //MARK: - General

    func moveFiles(files: [STLibrary.GaleryFile], toAlbum: STLibrary.Album, isMoving: Bool, reloadDBData: Bool = true, success: Success<STEmptyResponse>?, failure: Failure?) {
        self.moveFilesWithoutDelete(files: files, fromSet: .galery, toAlbum: toAlbum, isMoving: isMoving, reloadDBData: reloadDBData, success: { responce in
            if isMoving {
                let galleryProvider = STApplication.shared.dataBase.galleryProvider
                galleryProvider.delete(models: files, reloadData: reloadDBData)
            }
            success?(responce)
        }, failure: failure)
    }
    
    private func moveFilesWithoutDelete(files: [STLibrary.GaleryFile], fromSet: STLibrary.DBSet, toAlbum: STLibrary.Album, isMoving: Bool, reloadDBData: Bool = true, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        let crypto = STApplication.shared.crypto
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let uploader = STApplication.shared.uploader
        var newHeaders = [String: String]()
        
        func responceSuccess(newAlbumFiles: [STLibrary.AlbumFile]) {
            
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
                                               dateModified: Date(),
                                               managedObjectID: toAlbum.managedObjectID)

            albumFilesProvider.add(models: newAlbumFiles, reloadData: reloadDBData)
            albumsProvider.update(models: [updatedAlbum], reloadData: reloadDBData)

            success?(STEmptyResponse())
        }
        
        do {
            var newAlbumFiles = [STLibrary.AlbumFile]()
            var isRemoteFiles = [STLibrary.AlbumFile]()
            for file in files {
                guard let publicKey = crypto.base64ToByte(encodedStr: toAlbum.publicKey) else {
                    failure?(WorkerError.emptyData)
                    return
                }
                uploader.cancelUploadIng(for: file)
                let newHeader = try crypto.reencryptFileHeaders(headersStr: file.headers, publicKeyTo: publicKey, privateKeyFrom: nil, publicKeyFrom: nil)
                
                let newAlbumFile = STLibrary.AlbumFile(file: file.file,
                                                       version: file.version,
                                                       headers: newHeader,
                                                       dateCreated: file.dateCreated,
                                                       dateModified: Date(),
                                                       isRemote: file.isRemote,
                                                       isSynched: file.isSynched,
                                                       albumId: toAlbum.albumId,
                                                       managedObjectID: file.managedObjectID)
                if file.isRemote {
                    newHeaders[file.file] = newHeader
                    isRemoteFiles.append(newAlbumFile)
                }
                newAlbumFiles.append(newAlbumFile)
            }
            
            if isRemoteFiles.isEmpty {
                responceSuccess(newAlbumFiles: newAlbumFiles)
                return
            }
            
            let request = STAlbumRequest.moveFile(fromSet: fromSet, toSet: .album, albumIdFrom: nil, albumIdTo: toAlbum.albumId, isMoving: isMoving, headers: newHeaders, files: isRemoteFiles)
            
            self.request(request: request, success: { (response: STEmptyResponse) in
                responceSuccess(newAlbumFiles: newAlbumFiles)
            }, failure: failure)
     
        } catch {
            failure?(WorkerError.error(error: error))
        }
    }
    
    //MARK: - Album - Album
    
    func moveFiles(fromAlbum: STLibrary.Album, toAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isMoving: Bool, reloadDBData: Bool = true, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        var isRemoteFiles =  [STLibrary.AlbumFile]()
        
        let uploader = STApplication.shared.uploader
        let crypto = STApplication.shared.crypto
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        var newHeaders = [String: String]()
        
        func responceSuccess(newAlbumFiles: [STLibrary.AlbumFile]) {
            if isMoving {
                albumFilesProvider.delete(models: files, reloadData: reloadDBData)
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
                                               dateModified: Date(),
                                               managedObjectID: toAlbum.managedObjectID)
            
            albumFilesProvider.add(models: newAlbumFiles, reloadData: reloadDBData)
            albumsProvider.update(models: [updatedAlbum], reloadData: reloadDBData)
            success?(STEmptyResponse())
        }
        
        do {
            let fromAlbumData = try crypto.decryptAlbum(albumPKStr: fromAlbum.publicKey, encAlbumSKStr: fromAlbum.encPrivateKey, metadataStr: fromAlbum.metadata)
            var newAlbumFiles = [STLibrary.AlbumFile]()
            for file in files {
                
                uploader.cancelUploadIng(for: file)
                
                guard let publicKey = crypto.base64ToByte(encodedStr: toAlbum.publicKey) else {
                    failure?(WorkerError.emptyData)
                    return
                }
                let newHeader = try crypto.reencryptFileHeaders(headersStr: file.headers, publicKeyTo: publicKey, privateKeyFrom: fromAlbumData.privateKey, publicKeyFrom: fromAlbumData.publicKey)
                
                if file.isRemote {
                    newHeaders[file.file] = newHeader
                    isRemoteFiles.append(file)
                }
                
                let newAlbumFile = file.copy(headers: newHeader, dateModified: Date())
                newAlbumFiles.append(newAlbumFile)
            }
            
            if isRemoteFiles.isEmpty {
                responceSuccess(newAlbumFiles: newAlbumFiles)
                return
            }
            
            let request = STAlbumRequest.moveFile(fromSet: .album, toSet: .album, albumIdFrom: fromAlbum.albumId, albumIdTo: toAlbum.albumId, isMoving: isMoving, headers: newHeaders, files: isRemoteFiles)
            self.request(request: request, success: { (response: STEmptyResponse) in
                responceSuccess(newAlbumFiles: newAlbumFiles)
            }, failure: failure)
     
        } catch {
            failure?(WorkerError.error(error: error))
        }
    }
    
    func moveFilesToGallery(fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isMoving: Bool, reloadDBData: Bool = true, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        var isRemoteFiles =  [STLibrary.GaleryFile]()
        let crypto = STApplication.shared.crypto
        let uploader = STApplication.shared.uploader
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        
        func responceSuccess(galeryFiles: [STLibrary.GaleryFile]) {
            if isMoving {
                albumFilesProvider.delete(models: files, reloadData: reloadDBData)
            }
            galleryProvider.add(models: galeryFiles, reloadData: reloadDBData)
            success?(STEmptyResponse())
        }
        
        do {
            let publicKey = try crypto.readPublicKey()
            let fromAlbumData = try crypto.decryptAlbum(albumPKStr: fromAlbum.publicKey, encAlbumSKStr: fromAlbum.encPrivateKey, metadataStr: fromAlbum.metadata)
            
            var newHeaders = [String: String]()
            var galeryFiles = [STLibrary.GaleryFile]()
            
            for file in files {
                
                uploader.cancelUploadIng(for: file)
                
                let newHeader = try crypto.reencryptFileHeaders(headersStr: file.headers, publicKeyTo: publicKey, privateKeyFrom: fromAlbumData.privateKey, publicKeyFrom: fromAlbumData.publicKey)
                let file = STLibrary.GaleryFile(fileName: file.file,
                                              version: file.version,
                                              headers: newHeader,
                                              dateCreated: file.dateCreated,
                                              dateModified: file.dateModified,
                                              isRemote: file.isRemote,
                                              isSynched: file.isSynched,
                                              managedObjectID: file.managedObjectID)

                if file.isRemote {
                    newHeaders[file.file] = newHeader
                    isRemoteFiles.append(file)
                }
                galeryFiles.append(file)
            }
            
            if isRemoteFiles.isEmpty {
                responceSuccess(galeryFiles: galeryFiles)
                return
            }
            
            let request = STAlbumRequest.moveFile(fromSet: .album, toSet: .galery, albumIdFrom: fromAlbum.albumId, albumIdTo: nil, isMoving: isMoving, headers: newHeaders, files: isRemoteFiles)
            
            self.request(request: request, success: { (response: STEmptyResponse) in
                responceSuccess(galeryFiles: galeryFiles)
            }, failure: failure)
            
        } catch {
            failure?(WorkerError.error(error: error))
        }
        
    }
    
}
