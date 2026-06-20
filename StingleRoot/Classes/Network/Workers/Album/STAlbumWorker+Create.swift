//
//  STAlbumWorker+Create.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/9/21.
//

import Foundation

public extension STAlbumWorker {
    
    func createAlbum(name: String, reloadDBData: Bool = true, success: Success<STLibrary.Album>?, failure: Failure?) {
        do {
            let encryptedAlbumData = try STApplication.shared.crypto.generateEncryptedAlbumDataAndID(albumName: name)
            self.createAlbum(encryptedAlbumData: encryptedAlbumData, reloadDBData: reloadDBData, success: success, failure: failure)
        } catch {
            failure?(WorkerError.error(error: error))
        }
    }
    
    func createAlbum(name: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isMoving: Bool, success: Success<STLibrary.Album>? = nil, failure: Failure?) {
        self.createAlbum(name: name, reloadDBData: true, success: { [weak self] album in
            self?.moveFiles(fromAlbum: fromAlbum, toAlbum: album, files: files, isMoving: isMoving, success: { _ in
                success?(album)
            }, failure: failure)
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
                                    dateModified: now,
                                    managedObjectID: nil)
                
        let request = STAlbumRequest.create(album: album)
        self.request(request: request) { (response: STEmptyResponse) in
            STApplication.shared.dataBase.albumsProvider.add(models: [album], reloadData: reloadDBData)
            success?(album)
        } failure: { (error) in
            failure?(error)
        }
    }

}

//MARK: - async/await

public extension STAlbumWorker {

    func createAlbum(name: String, reloadDBData: Bool = true) async throws -> STLibrary.Album {
        try await withCheckedThrowingContinuation { continuation in
            self.createAlbum(name: name, reloadDBData: reloadDBData, success: { continuation.resume(returning: $0) },
                             failure: { continuation.resume(throwing: $0) })
        }
    }

    func createAlbum(name: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isMoving: Bool) async throws -> STLibrary.Album {
        try await withCheckedThrowingContinuation { continuation in
            self.createAlbum(name: name, fromAlbum: fromAlbum, files: files, isMoving: isMoving,
                             success: { continuation.resume(returning: $0) },
                             failure: { continuation.resume(throwing: $0) })
        }
    }

}
