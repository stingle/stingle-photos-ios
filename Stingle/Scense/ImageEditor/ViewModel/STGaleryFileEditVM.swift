//
//  STGaleryFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 3/31/22.
//

import UIKit

class STGaleryFileEditVM: IFileEditVM {
    var file: STLibrary.File

    init(file: STLibrary.File) {
        self.file = file
    }

    func save(image: UIImage) throws {
        STApplication.shared.uploader.cancelUploadIng(for: [self.file])
        guard let fileName = self.file.decryptsHeaders.file?.fileName else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName, existingFileName: self.file.file)
        let version = "\((Int(self.file.version) ?? .zero) + 1)"
        if self.file.isRemote {
            STApplication.shared.fileSystem.deleteFiles(files: [self.file])
        }
        let dateModified = Date()
        let file = try STLibrary.File(file: self.file.file, version: version, headers: encryptedFileInfo.headers, dateCreated: self.file.dateCreated, dateModified: dateModified, isRemote: false, managedObjectID: self.file.managedObjectID)
        STApplication.shared.dataBase.galleryProvider.update(models: [file], reloadData: true)
        STApplication.shared.uploader.upload(files: [file])
    }

    func saveAsNewFile(image: UIImage) throws {
        guard let fileName = self.file.decryptsHeaders.file?.fileName else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName)
        let version = "\(STCrypto.Constants.CurrentFileVersion)"
        let dateCreated = Date()
        let dateModified = Date()
        let file = try STLibrary.File(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, managedObjectID: nil)
        STApplication.shared.dataBase.galleryProvider.add(models: [file], reloadData: true)
        STApplication.shared.uploader.upload(files: [file])
    }

}
