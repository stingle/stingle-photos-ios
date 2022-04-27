//
//  STAlbumFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 3/31/22.
//

import UIKit

class STAlbumFileEditVM: IFileEditVM {

    var file: STLibrary.File
    var album: STLibrary.Album!

    init(file: STLibrary.File, album: STLibrary.Album) {
        self.file = file
        self.album = album
    }

    func save(image: UIImage) throws {
        STApplication.shared.uploader.cancelUploadIng(for: [self.file])
        guard let fileName = self.file.decryptsHeaders.file?.fileName, let publicKey = self.album.albumMetadata?.publicKey else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName, existingFileName: self.file.file, publicKey: publicKey)
        let version = "\((Int(self.file.version) ?? .zero) + 1)"
        if self.file.isRemote {
            STApplication.shared.fileSystem.deleteFiles(files: [self.file])
        }
        let dateModified = Date()
        let file = try STLibrary.AlbumFile(file: self.file.file, version: version, headers: encryptedFileInfo.headers, dateCreated: self.file.dateCreated, dateModified: dateModified, isRemote: false, albumId: self.album.albumId, managedObjectID: nil)
        STApplication.shared.dataBase.albumFilesProvider.update(models: [file], reloadData: true)
        let updatedAlbum = STLibrary.Album(album: self.album, dateModified: Date())
        STApplication.shared.dataBase.albumsProvider.update(models: [updatedAlbum], reloadData: true)
        file.updateIfNeeded(albumMetadata: updatedAlbum.albumMetadata)
        STApplication.shared.uploader.upload(files: [file])
    }

    func saveAsNewFile(image: UIImage) throws {
        guard let fileName = self.file.decryptsHeaders.file?.fileName, let publicKey = self.album.albumMetadata?.publicKey else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName, publicKey: publicKey)
        let version = "\(STCrypto.Constants.CurrentFileVersion)"
        let dateCreated = Date()
        let dateModified = Date()
        let file = try STLibrary.AlbumFile(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, albumId: self.album.albumId, managedObjectID: nil)
        STApplication.shared.dataBase.albumFilesProvider.add(models: [file], reloadData: true)
        let updatedAlbum = STLibrary.Album(album: self.album, dateModified: Date())
        STApplication.shared.dataBase.albumsProvider.update(models: [updatedAlbum], reloadData: true)
        file.updateIfNeeded(albumMetadata: updatedAlbum.albumMetadata)
        STApplication.shared.uploader.upload(files: [file])
    }

}
