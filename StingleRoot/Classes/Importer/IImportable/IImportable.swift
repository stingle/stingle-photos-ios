//
//  IUploadFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//


import UIKit

public extension STImporter {
    
    struct ImportFileInfo {
        let oreginalUrl: URL
        let thumbImage: Data
        let fileType: STHeader.FileType
        let duration: TimeInterval
        let fileSize: UInt
        let creationDate: Date?
        let modificationDate: Date?
        let freeBuffer: (() -> Void)?
    }
    
    typealias ProgressHandler = ((_ progress: Foundation.Progress, _ stop: inout Bool?) -> Void)
}

public protocol IImportable: AnyObject {}

/// IImportableFile
public protocol IImportableFile: IImportable {
    associatedtype File: ILibraryFile
    func requestFile(in queue: DispatchQueue?, progressHandler: STImporter.ProgressHandler?, success: @escaping (File) -> Void, failure: @escaping (IError) -> Void)
    func createUploadFile(info: STImporter.ImportFileInfo, progressHandler: @escaping STImporter.ProgressHandler) throws -> File
    func requestData(in queue: DispatchQueue?, progress: STImporter.ProgressHandler?, success: @escaping (_ uploadInfo: STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void)
    func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, progressHandler: @escaping STImporter.ProgressHandler) throws -> File
}

public extension IImportableFile {
    
    func requestFile(in queue: DispatchQueue?, progressHandler: STImporter.ProgressHandler?, success: @escaping (File) -> Void, failure: @escaping (IError) -> Void) {
        
        let totalProgress = Progress()
        totalProgress.totalUnitCount = 10000
        var progressValue = Double.zero
       
        self.requestData(in: queue, progress: { progress, stop in
            progressValue = progress.fractionCompleted / 4
            totalProgress.completedUnitCount = Int64(progressValue * Double(totalProgress.totalUnitCount))
            progressHandler?(totalProgress, &stop)
        }, success: { [weak self] uploadInfo in
            guard let weakSelf = self else {
                failure(STFileUploader.UploaderError.fileNotFound)
                return
            }
            let freeDiskUnits = STFileSystem.DiskStatus.freeDiskSpaceUnits
            let afterImportfreeDiskUnits = STBytesUnits(bytes: freeDiskUnits.bytes - Int64(uploadInfo.fileSize))
            
            guard afterImportfreeDiskUnits > STConstants.minFreeDiskUnits else {
                failure(STFileUploader.UploaderError.memoryLow)
                return
            }
            do {
                //TODO: Configure shearch indexes
                let file = try weakSelf.createUploadFile(info: uploadInfo, progressHandler: { progress,stop in
                    progressValue = 0.25 + progress.fractionCompleted / (4 / 3)
                    totalProgress.completedUnitCount = Int64(progressValue * Double(totalProgress.totalUnitCount))
                    progressHandler?(totalProgress, &stop)
                })
                success(file)
            } catch {
                failure(STFileUploader.UploaderError.error(error: error))
            }
        }, failure: failure)
    }
    
    func createUploadFile(info: STImporter.ImportFileInfo, progressHandler: @escaping STImporter.ProgressHandler) throws -> File {
       
        guard STApplication.shared.isFileSystemAvailable else {
            throw STFileUploader.UploaderError.fileSystemNotValid
        }
        
        let fileSystem = STApplication.shared.fileSystem
        
        guard let localThumbsURL = fileSystem.localThumbsURL, let localOreginalsURL = fileSystem.localOreginalsURL else {
            throw STFileUploader.UploaderError.fileSystemNotValid
        }
        
        let file = try self.createFile(fileType: info.fileType,
                                       oreginalUrl: info.oreginalUrl,
                                       thumbImageData: info.thumbImage,
                                       duration: info.duration,
                                       toUrl: localOreginalsURL,
                                       toThumbUrl: localThumbsURL,
                                       fileSize: info.fileSize,
                                       creationDate: info.creationDate,
                                       modificationDate: info.modificationDate,
                                       progressHandler: progressHandler)
        
        return file
    }
    
}

/// IImportableGaleryFile
public protocol IImportableGaleryFile: IImportableFile where File: STLibrary.GaleryFile {}

public extension IImportableGaleryFile {
    
    func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, progressHandler: @escaping STImporter.ProgressHandler) throws -> STLibrary.GaleryFile {

        let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(oreginalUrl: oreginalUrl, thumbImage: thumbImageData, fileType: fileType, duration: duration, toUrl: toUrl, toThumbUrl: toThumbUrl, fileSize: fileSize, progressHandler: { progress, stop in
            var isEnded: Bool?
            progressHandler(progress, &isEnded)
            if let isEnded = isEnded {
                stop = isEnded
            }
        })

        let version = "\(STCrypto.Constants.CurrentFileVersion)"
        let dateCreated = creationDate ?? Date()
        let dateModified = modificationDate ?? Date()

        let file = STLibrary.GaleryFile(fileName: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, isSynched: false, managedObjectID: nil)
        return file
    }
}

/// IImportableGaleryFile
public protocol IImportableAlbumFile: IImportableFile where File: STLibrary.AlbumFile {
    var album: STLibrary.Album { get }
}

public extension IImportableAlbumFile {
    
    func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, progressHandler: @escaping STImporter.ProgressHandler) throws -> STLibrary.AlbumFile {
        
        guard let publicKey = self.album.albumMetadata?.publicKey else {
            throw STFileUploader.UploaderError.fileNotFound
        }
        let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(oreginalUrl: oreginalUrl, thumbImage: thumbImageData, fileType: fileType, duration: duration, toUrl: toUrl, toThumbUrl: toThumbUrl, fileSize: fileSize, publicKey: publicKey, progressHandler: { progress, stop in
            var isEnded: Bool?
            progressHandler(progress, &isEnded)
            if let isEnded = isEnded {
                stop = isEnded
            }
        })

        let version = "\(STCrypto.Constants.CurrentFileVersion)"
        let dateCreated = creationDate ?? Date()
        let dateModified = modificationDate ?? Date()
        let file = STLibrary.AlbumFile(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, isSynched: false, albumId: self.album.albumId, managedObjectID: nil)
        file.updateIfNeeded(albumMetadata: self.album.albumMetadata)
        return file
    }
    
}

public extension STImporter {
    typealias GaleryImportable = IImportableGaleryFile
    typealias AlbumFileImportable = IImportableAlbumFile
}
