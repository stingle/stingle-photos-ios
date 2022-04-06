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

    func save(image: UIImage) {

        STApplication.shared.uploader.cancelUploadIng(for: [self.file])

        do {
            guard let fileName = self.file.decryptsHeaders.file?.fileName else {
                return
            }
            let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName, existingFileName: self.file.file)
            let version = "\((Int(self.file.version) ?? .zero) + 1)"
            if self.file.isRemote {
                STApplication.shared.fileSystem.deleteFiles(files: [self.file])
            }
            let file = try STLibrary.File(file: self.file.file, version: version, headers: encryptedFileInfo.headers, dateCreated: self.file.dateCreated, dateModified: Date(), isRemote: false, managedObjectID: self.file.managedObjectID)

            STApplication.shared.dataBase.galleryProvider.update(models: [file], reloadData: true)
            STApplication.shared.uploader.upload(files: [file])
        } catch {
            print(error.localizedDescription)
        }
    }

    func saveAsNewFile(image: UIImage) {
        do {
            guard let fileName = self.file.decryptsHeaders.file?.fileName else {
                return
            }
            let encryptedFileInfo = try self.saveNewImage(image: image, fileName: fileName)
            let version = "\(STCrypto.Constants.CurrentFileVersion)"
            let dateCreated = Date()
            let dateModified = Date()
            let file = try STLibrary.File(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, managedObjectID: nil)
            STApplication.shared.dataBase.galleryProvider.add(models: [file], reloadData: true)
            STApplication.shared.uploader.upload(files: [file])
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: - Private methods

    private func saveNewImage(image: UIImage, fileName: String, existingFileName: String? = nil) throws -> (fileName: String, thumbUrl: URL, originalUrl: URL, headers: String) {
        let tmpFolder = FileManager.default.temporaryDirectory
        let size = STConstants.thumbSize(for: CGSize(width: image.size.width, height: image.size.height))
        let thumb = image.scaled(newSize: size)
        guard let data = image.jpegData(compressionQuality: 1.0), let thumbData = thumb.jpegData(compressionQuality: 0.7) else {
            throw STError.fileIsUnavailable
        }
        var filePath = tmpFolder.appendingPathComponent("edited.images")
        do {
            try FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: true)
            filePath.appendPathComponent(fileName)
            filePath.deletePathExtension()
            filePath.appendPathExtension("jpeg")

            try data.write(to: filePath)

            let fileSystem = STApplication.shared.fileSystem
            guard let localThumbsURL = fileSystem.localThumbsURL, let localOreginalsURL = fileSystem.localOreginalsURL else {
                throw STFileUploader.UploaderError.fileSystemNotValid
            }
            let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(fileName: existingFileName, oreginalUrl: filePath, thumbImage: thumbData, fileType: .image, duration: 0.0, toUrl: localOreginalsURL, toThumbUrl: localThumbsURL, fileSize: UInt(data.count))

            return encryptedFileInfo
        } catch {
            if FileManager.default.fileExists(atPath: filePath.path) {
                try? FileManager.default.removeItem(at: filePath)
            }
            throw error
        }
    }

}
