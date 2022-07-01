//
//  STGaleryFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 3/31/22.
//

import UIKit

class STGaleryFileEditVM: IFileEditVM {
    
    let galeryFile: STLibrary.GaleryFile
    
    var file: ILibraryFile {
        return self.galeryFile
    }

    init(file: STLibrary.GaleryFile) {
        self.galeryFile = file
    }

    func save(image: UIImage) throws {
        STApplication.shared.uploader.cancelUploadIng(for: [self.file])
        guard let fileName = self.file.decryptsHeaders.file?.fileName else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName, existingFileName: self.file.file)
        let version = "\((Int(self.file.version) ?? .zero) + 1)"
        if self.file.isRemote && self.file.isSynched {
            STApplication.shared.fileSystem.deleteFiles(files: [self.file])
        }
        let dateModified = Date()
        let file =  self.galeryFile.copy(version: version, headers: encryptedFileInfo.headers, dateModified: dateModified, isSynched: false)
        STApplication.shared.dataBase.galleryProvider.update(models: [file], reloadData: true)
        STApplication.shared.uploader.upload(files: [file])
    }

    func saveAsNewFile(image: UIImage) throws {
        guard let fileName = self.file.decryptsHeaders.file?.fileName else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName)
        let version = "\(STCrypto.Constants.CurrentFileVersion)"
        let date = Date()
        // TODO: Shahen run image recognition to update edited image faces/objects info.
        let file =  STLibrary.GaleryFile(fileName: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: date, dateModified: date, isRemote: false, isSynched: false, searchIndexes: self.file.searchIndexes, managedObjectID: nil)
        STApplication.shared.dataBase.galleryProvider.add(models: [file], reloadData: true)
        STApplication.shared.uploader.upload(files: [file])
    }

}
