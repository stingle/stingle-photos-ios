//
//  IUploadFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import Photos
import UIKit

protocol IImportable {
            
    func requestData(in queue: DispatchQueue?, progress: STImporter.ProgressHandler?, success: @escaping (_ uploadInfo: STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void)
    
    func requestFile(in queue: DispatchQueue?, progressHandler: STImporter.ProgressHandler?, success: @escaping (_ file: STLibrary.File) -> Void, failure: @escaping (_ failure: IError ) -> Void)
    
}

extension STImporter {
    
    struct ImportFileInfo {
        let oreginalUrl: URL
        let thumbImage: Data
        let fileType: STFileUploader.FileType
        let duration: TimeInterval
        let fileSize: UInt
        let creationDate: Date?
        let modificationDate: Date?
        let freeBuffer: (() -> Void)?
    }
    
    typealias ProgressHandler = ((_ progress: Foundation.Progress, _ stop: inout Bool?) -> Void)
    
    class FileImportable: IImportable {
        
        let asset: PHAsset
        
        init(asset: PHAsset) {
            self.asset = asset
        }
        
        func requestFile(in queue: DispatchQueue?, progressHandler: ProgressHandler?, success: @escaping (_ file: STLibrary.File) -> Void, failure: @escaping (_ failure: IError ) -> Void) {
            
            let totalProgress = Progress()
            totalProgress.totalUnitCount = 10000
            var progressValue = Double.zero
            
            print("bbbbbbb requestFile", self.asset.localIdentifier)
            
            self.requestData(in: queue, progress: { progress, stop in
                progressValue = progress.fractionCompleted / 4
                totalProgress.completedUnitCount = Int64(progressValue * Double(totalProgress.totalUnitCount))
                progressHandler?(totalProgress, &stop)
            }, success: { [weak self] uploadInfo in
                guard let weakSelf = self else {
                    uploadInfo.freeBuffer?()
                    failure(STFileUploader.UploaderError.fileNotFound)
                    return
                }
                let freeDiskUnits = STFileSystem.DiskStatus.freeDiskSpaceUnits
                let afterImportfreeDiskUnits = STBytesUnits(bytes: freeDiskUnits.bytes - Int64(uploadInfo.fileSize))
                
                guard afterImportfreeDiskUnits > STConstants.minFreeDiskUnits else {
                    uploadInfo.freeBuffer?()
                    failure(STFileUploader.UploaderError.memoryLow)
                    return
                }
                print("bbbbbbb requestData", weakSelf.asset.localIdentifier)
                
                do {
                    let file = try weakSelf.createUploadFile(info: uploadInfo, progressHandler: { progress,stop in
                        progressValue = 0.25 + progress.fractionCompleted / (4 / 3)
                        totalProgress.completedUnitCount = Int64(progressValue * Double(totalProgress.totalUnitCount))
                        progressHandler?(totalProgress, &stop)
                        print("bbbbbbb requestData", weakSelf.asset.localIdentifier, progress.fractionCompleted)
                    })
                    uploadInfo.freeBuffer?()
                    success(file)
                } catch {
                    uploadInfo.freeBuffer?()
                    failure(STFileUploader.UploaderError.error(error: error))
                }
            }, failure: failure)
        }

        func createUploadFile(info: ImportFileInfo, progressHandler: @escaping ProgressHandler) throws -> STLibrary.File {
            var fileType: STHeader.FileType!
            switch info.fileType {
            case .image:
                fileType = .image
            case .video:
                fileType = .video
            default:
                throw STFileUploader.UploaderError.phAssetNotValid
            }
            
            guard STApplication.shared.isFileSystemAvailable else {
                throw STFileUploader.UploaderError.fileSystemNotValid
            }
            
            let fileSystem = STApplication.shared.fileSystem
            
            guard let localThumbsURL = fileSystem.localThumbsURL, let localOreginalsURL = fileSystem.localOreginalsURL else {
                throw STFileUploader.UploaderError.fileSystemNotValid
            }
            
            let file = try self.createFile(fileType: fileType,
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
        
        func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, progressHandler: @escaping ProgressHandler) throws -> STLibrary.File {
            
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

            let file = try STLibrary.File(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, managedObjectID: nil)
            
            return file
        }
        
        func requestData(in queue: DispatchQueue?, progress: ProgressHandler?, success: @escaping (_ uploadInfo: ImportFileInfo) -> Void, failure: @escaping (IError) -> Void) {
                        
            guard let fileType = STFileUploader.FileType(rawValue: self.asset.mediaType.rawValue) else {
                failure(STFileUploader.UploaderError.phAssetNotValid)
                return
            }

            func compled(error: IError) {
                if let queue = queue {
                    queue.async {
                        failure(error)
                    }
                } else {
                    failure(error)
                }
            }
            
            func compled(uploadInfo: ImportFileInfo) {
                if let queue = queue {
                    queue.async {
                        success(uploadInfo)
                    }
                } else {
                    success(uploadInfo)
                }
            }

            let totalProgress = Progress()
            totalProgress.totalUnitCount = 10000
            var myProgressValue = Double.zero
            
            print("bbbbbbb PHPhoto requestGetURL")
            
            STPHPhotoHelper.requestGetURL(asset: self.asset, queue: queue, progressHandler: { progressValue, stop in
               
                myProgressValue = progressValue / 2
                totalProgress.completedUnitCount = Int64(myProgressValue * Double(totalProgress.totalUnitCount))
                var isEnd: Bool? = false
                
                progress?(totalProgress, &isEnd)
                if let isEnd = isEnd {
                    stop?.pointee = ObjCBool(isEnd)
                }
                
                print("bbbbbbb PHPhoto requestGetURL, progress")
                
            }) { [weak self] info in
                
                
                print("bbbbbbb PHPhoto requestGetURL, info")
                
                guard let weakSelf = self, let info = info else {
                    compled(error: STFileUploader.UploaderError.phAssetNotValid)
                    return
                }
                
                print("bbbbbbb PHPhoto requestGetURL, requestThumb")
                
                STPHPhotoHelper.requestThumb(asset: weakSelf.asset, queue: queue, progressHandler: { progressValue, stop in
                    
                    myProgressValue = 0.5 + progressValue / 2
                    totalProgress.completedUnitCount = Int64(myProgressValue * Double(totalProgress.totalUnitCount))
                    var isEnd: Bool? = false
                    progress?(totalProgress, &isEnd)
                    if let isEnd = isEnd {
                        stop?.pointee = ObjCBool(isEnd)
                    }
                    
                }) { image in
                    guard let image = image, let thumbData = image.jpegData(compressionQuality: 0.7)  else {
                        compled(error: STFileUploader.UploaderError.phAssetNotValid)
                        info.freeBuffer?()
                        return
                    }
                    
                    let uploadInfo = ImportFileInfo(oreginalUrl: info.dataInfo,
                                                                    thumbImage: thumbData,
                                                                    fileType: fileType,
                                                                    duration: info.videoDuration,
                                                                    fileSize: info.fileSize,
                                                                    creationDate: info.creationDate,
                                                                    modificationDate: info.modificationDate,
                                                                    freeBuffer: info.freeBuffer)
                    compled(uploadInfo: uploadInfo)
                }
            }
        }
        
    }
    
}

extension STImporter {
    
    class AlbumFileImportable: FileImportable {
        
        let album: STLibrary.Album
        
        init(asset: PHAsset, album: STLibrary.Album) {
            self.album = album
            super.init(asset: asset)
        }
                
        override func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, progressHandler: @escaping ProgressHandler) throws -> STLibrary.File {
            
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
            
            let file = try STLibrary.AlbumFile(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, albumId: self.album.albumId, managedObjectID: nil)
            file.updateIfNeeded(albumMetadata: self.album.albumMetadata)
            return file
        }
        
    }
    
}


extension AVURLAsset {
    
    var fileSize: UInt? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        guard let size = resourceValues?.fileSize ?? resourceValues?.totalFileSize else {
            return nil
        }
        return UInt(size)
    }
}
