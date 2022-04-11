//
//  IFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 4/1/22.
//

import UIKit
import Sodium

protocol IFileEditVM: AnyObject {
    var file: STLibrary.File { get }
    func save(image: UIImage) throws
    func saveAsNewFile(image: UIImage) throws

    func save(image: UIImage, hendler: @escaping (_ error: IError?) -> Void)
    func saveAsNewFile(image: UIImage, hendler: @escaping (_ error: IError?) -> Void)
}

extension IFileEditVM {

    func saveNewImage(image: UIImage, fileName: String, existingFileName: String? = nil, publicKey: Bytes? = nil) throws -> (fileName: String, thumbUrl: URL, originalUrl: URL, headers: String) {
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
            let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(fileName: existingFileName, oreginalUrl: filePath, thumbImage: thumbData, fileType: .image, duration: 0.0, toUrl: localOreginalsURL, toThumbUrl: localThumbsURL, fileSize: UInt(data.count), publicKey: publicKey, progressHandler: nil)

            if FileManager.default.fileExists(atPath: filePath.path) {
                try? FileManager.default.removeItem(at: filePath)
            }

            return encryptedFileInfo
        } catch {
            if FileManager.default.fileExists(atPath: filePath.path) {
                try? FileManager.default.removeItem(at: filePath)
            }
            throw error
        }
    }

    func save(image: UIImage, hendler: @escaping (_ error: IError?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.save(image: image)
                DispatchQueue.main.async {
                    hendler(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    hendler(STError.error(error: error))
                }
            }
        }
    }

    func saveAsNewFile(image: UIImage, hendler: @escaping (_ error: IError?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.saveAsNewFile(image: image)
                DispatchQueue.main.async {
                    hendler(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    hendler(STError.error(error: error))
                }
            }
        }
    }

}
