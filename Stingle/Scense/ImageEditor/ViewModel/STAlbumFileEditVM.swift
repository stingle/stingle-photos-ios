//
//  STAlbumFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 3/31/22.
//

import UIKit
import CoreData
import StingleRoot

class STAlbumFileEditVM: IFileEditVM {
    
    let albumFile: STLibrary.AlbumFile
    let album: STLibrary.Album!
    
    var file: STLibrary.FileBase {
        return self.albumFile
    }

    init(file: STLibrary.AlbumFile, album: STLibrary.Album) {
        self.albumFile = file
        self.album = album
    }

    func save(image: UIImage) throws {
        STApplication.shared.uploader.cancelUploadIng(for: [self.file])
        guard let fileName = self.file.decryptsHeaders.file?.fileName, let publicKey = self.album.albumMetadata?.publicKey else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName, existingFileName: self.file.file, publicKey: publicKey)
        let version = "\((Int(self.file.version) ?? .zero) + 1)"
        if self.file.isRemote && self.file.isSynched {
            STApplication.shared.fileSystem.deleteFiles(files: [self.file])
        }
        let dateModified = Date()
        
        let file = self.albumFile.copy(version: version, headers: encryptedFileInfo.headers, dateModified: dateModified, isSynched: false)
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
        let date = Date()
        
        let file = STLibrary.AlbumFile(file: self.file.file, version: version, headers: encryptedFileInfo.headers, dateCreated: date, dateModified: date, isRemote: false, isSynched: false, albumId: self.albumFile.albumId, managedObjectID: nil)
        
        STApplication.shared.dataBase.albumFilesProvider.add(models: [file], reloadData: true)
        let updatedAlbum = STLibrary.Album(album: self.album, dateModified: Date())
        STApplication.shared.dataBase.albumsProvider.update(models: [updatedAlbum], reloadData: true)
        file.updateIfNeeded(albumMetadata: updatedAlbum.albumMetadata)
        STApplication.shared.uploader.upload(files: [file])
    }

}
