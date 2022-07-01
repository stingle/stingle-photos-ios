//
//  IUploadFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import Photos
import UIKit

protocol IImportable { }

extension STImporter {
    
    struct ImportFileInfo {
        let oreginalUrl: URL
        let thumbImage: Data
        let fileType: STFileUploader.FileType
        let duration: TimeInterval
        let fileSize: UInt
        let creationDate: Date?
        let modificationDate: Date?
        let searchIndexes: [STLibrary.SearchIndex]?
        let freeBuffer: (() -> Void)?
    }
    
    typealias ProgressHandler = ((_ progress: Foundation.Progress, _ stop: inout Bool?) -> Void)
    
    class ImportableFile<File: ILibraryFile>: IImportable {
        
        let asset: PHAsset
        
        init(asset: PHAsset) {
            self.asset = asset
        }
        
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

        func createUploadFile(info: ImportFileInfo, progressHandler: @escaping ProgressHandler) throws -> File {
            
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
                                           searchIndexes: info.searchIndexes,
                                           progressHandler: progressHandler)
            
            return file
        }
        
        func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, searchIndexes: [STLibrary.SearchIndex]?, progressHandler: @escaping ProgressHandler) throws -> File {
            fatalError("implement childe classes")
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
            STPHPhotoHelper.requestGetURL(asset: self.asset, queue: queue, progressHandler: { progressValue, stop in
               
                myProgressValue = progressValue / 2
                totalProgress.completedUnitCount = Int64(myProgressValue * Double(totalProgress.totalUnitCount))
                var isEnd: Bool? = false
                
                progress?(totalProgress, &isEnd)
                if let isEnd = isEnd {
                    stop?.pointee = ObjCBool(isEnd)
                }
            }) { [weak self] info in
                guard let weakSelf = self, let info = info else {
                    compled(error: STFileUploader.UploaderError.phAssetNotValid)
                    return
                }

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
                        return
                    }
                    let completion: STImageRecognition.Completion = { searchInfos in
                        let importFileInfo = ImportFileInfo(oreginalUrl: info.dataInfo,
                                                            thumbImage: thumbData,
                                                            fileType: fileType,
                                                            duration: info.videoDuration,
                                                            fileSize: info.fileSize,
                                                            creationDate: info.creationDate,
                                                            modificationDate: info.modificationDate,
                                                            searchIndexes: searchInfos,
                                                            freeBuffer: info.freeBuffer)
                        compled(uploadInfo: importFileInfo)
                    }
                    switch weakSelf.asset.mediaType {
                    case .image:
                        STImageRecognition.shared.processImage(url: info.dataInfo, completion: completion)
                    case .video:
                        STImageRecognition.shared.processVideo(url: info.dataInfo, completion: completion)
                    default:
                        completion(nil)
                    }
                }
            }
        }
        
    }
    
}

extension STImporter {
    
    class GaleryFileImportable: ImportableFile<STLibrary.GaleryFile> {
        
        override func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, searchIndexes: [STLibrary.SearchIndex]?, progressHandler: @escaping STImporter.ProgressHandler) throws -> STLibrary.GaleryFile {
            
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

            let file = STLibrary.GaleryFile(fileName: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, isSynched: false, searchIndexes: searchIndexes, managedObjectID: nil)
            searchIndexes?.forEach({ $0.fileName = file.file })
            return file
        }
        
    }
    
    class AlbumFileImportable: ImportableFile<STLibrary.AlbumFile> {
        
        let album: STLibrary.Album
        
        init(asset: PHAsset, album: STLibrary.Album) {
            self.album = album
            super.init(asset: asset)
        }
        
        override func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?, searchIndexes: [STLibrary.SearchIndex]?, progressHandler: @escaping STImporter.ProgressHandler) throws -> STLibrary.AlbumFile {
            
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

            let file = STLibrary.AlbumFile(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, isSynched: false, albumId: self.album.albumId, searchIndexes: searchIndexes, managedObjectID: nil)
            searchIndexes?.forEach({ $0.fileName = file.file })
            file.searchIndexes = searchIndexes
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
