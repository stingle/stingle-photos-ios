//
//  IFileEditVM.swift
//  Stingle
//
//  Created by Shahen Antonyan on 4/1/22.
//

import UIKit
import StingleRoot
import UniformTypeIdentifiers
import Sodium

protocol IFileEditVM: AnyObject {
    var file: STLibrary.FileBase { get }
    
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
        var fileExtension = (fileName as NSString).pathExtension
        var type = UTType(filenameExtension: fileExtension) ?? .jpeg
        if !self.isTypeSupported(type: type) {
            type = .jpeg
            fileExtension = type.preferredFilenameExtension ?? "jpeg"
        }
        guard var heicData = image.imageData(for: type), var thumbData = thumb.jpegData(compressionQuality: 0.7) else {
            throw STError.fileIsUnavailable
        }
        if var properties = self.fileProperties() as? [String: Any] {
            properties["Orientation"] = 1
            let cfProperties = properties as CFDictionary
            heicData = self.appendingProperties(cfProperties, imageData: heicData)
            thumbData = self.appendingProperties(cfProperties, imageData: thumbData)
        }
        var filePath = tmpFolder.appendingPathComponent("edited.images")
        do {
            try FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: true)
            filePath.appendPathComponent(fileName)
            filePath.deletePathExtension()
            filePath.appendPathExtension(fileExtension)

            try heicData.write(to: filePath)
            
            guard STApplication.shared.isFileSystemAvailable else {
                throw STFileUploader.UploaderError.fileSystemNotValid
            }

            let fileSystem = STApplication.shared.fileSystem
            guard let localThumbsURL = fileSystem.localThumbsURL, let localOreginalsURL = fileSystem.localOreginalsURL else {
                throw STFileUploader.UploaderError.fileSystemNotValid
            }
            let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(fileName: existingFileName, oreginalUrl: filePath, thumbImage: thumbData, fileType: .image, duration: 0.0, toUrl: localOreginalsURL, toThumbUrl: localThumbsURL, fileSize: UInt(heicData.count), publicKey: publicKey, progressHandler: nil)
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

    // MARK: - Private methods

    private func appendingProperties(_ properties: CFDictionary, imageData: Data) -> Data {
        let imageRef: CGImageSource = CGImageSourceCreateWithData((imageData as CFData), nil)!
        let uti: CFString = CGImageSourceGetType(imageRef)!
        let dataWithEXIF: NSMutableData = NSMutableData(data: imageData)
        let destination: CGImageDestination = CGImageDestinationCreateWithData((dataWithEXIF as CFMutableData), uti, 1, nil)!

        CGImageDestinationAddImageFromSource(destination, imageRef, 0, properties)
        CGImageDestinationFinalize(destination)

        return dataWithEXIF as Data
    }

    private func fileProperties() -> CFDictionary? {
        do {
            guard let url = self.file.fileOreginalUrl else {
                return nil
            }
            let data = try Data(contentsOf: url)
            let decryptedData = try STApplication.shared.crypto.decryptData(data: data, header: self.file.decryptsHeaders.file)
            if let source = CGImageSourceCreateWithData(decryptedData as CFData, nil) {
                return CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            }
            return nil
        } catch {
            return nil
        }
    }

    private func isTypeSupported(type: UTType) -> Bool {
        return (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(type.identifier)
    }

}
