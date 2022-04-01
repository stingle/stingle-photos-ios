//
//  STGaleryFileEditVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 3/31/22.
//

import UIKit

class STGaleryFileEditVC: IFileEditVM {
    var file: STLibrary.File

    init(file: STLibrary.File) {
        self.file = file
    }

    func save(image: UIImage) {
        STApplication.shared.uploader.cancelUploadIng(for: [self.file])
//        if let url = self.file.fileThumbUrl {
//            STApplication.shared.fileSystem.remove(file: url)
//        }
//        if let url = self.file.fileOreginalUrl {
//            STApplication.shared.fileSystem.remove(file: url)
//        }

//        STApplication.shared.crypto.createEncryptedFile(oreginalUrl: <#T##URL#>, thumbImage: <#T##Data#>, fileType: <#T##STHeader.FileType#>, duration: <#T##TimeInterval#>, toUrl: <#T##URL#>, toThumbUrl: <#T##URL#>, fileSize: <#T##UInt#>)
//
////
//
//
//        STApplication.shared.crypto.encryptFile(inputData: <#T##Data#>, outputUrl: <#T##URL#>, fileName: <#T##String#>, originalFileName: <#T##String#>, fileType: <#T##Int#>, fileId: <#T##Bytes#>, videoDuration: <#T##UInt32#>)
//
//        STApplication.shared.crypto.encryptData(input: <#T##InputStream#>, output: <#T##OutputStream#>, header: <#T##STHeader#>)

//        STApplication.shared.crypto.encryptFile(input: <#T##InputStream#>, output: <#T##OutputStream#>, filename: <#T##String#>, fileType: <#T##Int#>, dataLength: <#T##UInt#>, fileId: <#T##Bytes#>, videoDuration: <#T##UInt32#>)
//
//        STApplication.shared.crypto.encryptFile(inputData: <#T##Data#>, outputUrl: <#T##URL#>, fileName: <#T##String#>, originalFileName: <#T##String#>, fileType: <#T##Int#>, fileId: <#T##Bytes#>, videoDuration: <#T##UInt32#>)

        do {
            let version = "\((Int(self.file.version) ?? .zero) + 1)"
            let file = try STLibrary.File(file: self.file.file, version: version, headers: self.file.headers, dateCreated: self.file.dateCreated, dateModified: Date(), isRemote: false, managedObjectID: self.file.managedObjectID)

            guard let originalURL = file.fileOreginalUrl?.deletingLastPathComponent(), let thumURL = file.fileThumbUrl?.deletingLastPathComponent(), let data = image.jpegData(compressionQuality: 1.0) else {
                return
            }


            guard let fileHeaders = file.decryptsHeaders.file, let fileName = fileHeaders.fileName else {
                return
            }

            let size = STConstants.thumbSize(for: CGSize(width: image.size.width, height: image.size.height))
            let thumb = image.scaled(newSize: size)
            guard let thumbHeaders = file.decryptsHeaders.thumb, let thumbFileName = thumbHeaders.fileName, let thumbData = thumb.jpegData(compressionQuality: 0.7) else {
                return
            }

            try STApplication.shared.crypto.encryptFile(inputData: data, outputUrl: originalURL, fileName: file.file, originalFileName: fileName, fileType: Int(fileHeaders.fileType), fileId: fileHeaders.fileId, videoDuration: fileHeaders.videoDuration)


            try STApplication.shared.crypto.encryptFile(inputData: thumbData, outputUrl: thumURL, fileName: file.file, originalFileName: thumbFileName, fileType: Int(thumbHeaders.fileType), fileId: thumbHeaders.fileId, videoDuration: thumbHeaders.videoDuration)

            STApplication.shared.dataBase.galleryProvider.update(models: [file], reloadData: true)

            STApplication.shared.uploader.upload(files: [file])
        } catch {
            print(error.localizedDescription)
            // Implement error case
        }

//        let file = STLibrary.AlbumFile(file: <#T##String?#>, version: <#T##String?#>, headers: <#T##String?#>, dateCreated: <#T##Date?#>, dateModified: <#T##Date?#>, isRemote: <#T##Bool#>, albumId: <#T##String#>, managedObjectID: <#T##NSManagedObjectID?#>)

//        let th = image.pngData()
//        STApplication.shared.crypto
    }

    func saveAsNewFile(image: UIImage) {
        
    }

}
