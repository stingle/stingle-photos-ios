//
//  IUploadFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import Photos
import UIKit

protocol IUploadFile {
    func requestFile(in queue: DispatchQueue?, success: @escaping (_ file: STLibrary.File) -> Void, failure: @escaping (_ failure: IError ) -> Void)
}

extension STFileUploader {
    
    class FileUploadable: IUploadFile {
        
        let asset: PHAsset
        
        init(asset: PHAsset) {
            self.asset = asset
        }
        
        func requestFile(in queue: DispatchQueue?, success: @escaping (_ file: STLibrary.File) -> Void, failure: @escaping (_ failure: IError ) -> Void) {
            
            self.requestData(in: queue, success: { [weak self] uploadInfo in
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
                    let file = try weakSelf.createUploadFile(info: uploadInfo)
                    success(file)
                } catch {
                    failure(STFileUploader.UploaderError.error(error: error))
                }
                
            }, failure: failure)
        }

        func createUploadFile(info: STFileUploader.UploadFileInfo) throws -> STLibrary.File {
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
                                     modificationDate: info.modificationDate)
            
            return file
        }
        
        func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?) throws -> STLibrary.File {
            
            let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(oreginalUrl: oreginalUrl, thumbImage: thumbImageData, fileType: fileType, duration: duration, toUrl: toUrl, toThumbUrl: toThumbUrl, fileSize: fileSize)
            
            let version = "\(STCrypto.Constants.CurrentFileVersion)"
            let dateCreated = creationDate ?? Date()
            let dateModified = modificationDate ?? Date()

            let file = try STLibrary.File(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, managedObjectID: nil)
            
            return file
        }
        
        func requestData(in queue: DispatchQueue?, success: @escaping (_ uploadInfo: STFileUploader.UploadFileInfo) -> Void, failure: @escaping (IError) -> Void) {
                        
            guard let fileType = STFileUploader.FileType(rawValue: self.asset.mediaType.rawValue) else {
                failure(STFileUploader.UploaderError.phAssetNotValid)
                return
            }
                        
            self.asset.requestGetURL(in: queue) { [weak self] info in
                guard let info = info else {
                    failure(STFileUploader.UploaderError.phAssetNotValid)
                    return
                }
                
                self?.asset.requestGetThumb(in: queue, completion: { thumbImage in
                    guard let thumb = thumbImage, let thumbData = thumb.jpegData(compressionQuality: 0.7) else {
                        failure(STFileUploader.UploaderError.phAssetNotValid)
                        return
                    }
                    let uploadInfo = STFileUploader.UploadFileInfo(oreginalUrl: info.url,
                                                                   thumbImage: thumbData,
                                                                   fileType: fileType,
                                                                   duration: info.videoDuration,
                                                                   fileSize: info.fileSize,
                                                                   creationDate: info.creationDate,
                                                                   modificationDate: info.modificationDate)
                    success(uploadInfo)
                })
            }
            
        }
        
    }
    
}

extension STFileUploader {
    
    class AlbumFileUploadable: FileUploadable {
        
        let album: STLibrary.Album
        
        init(asset: PHAsset, album: STLibrary.Album) {
            self.album = album
            super.init(asset: asset)
        }
                
        override func createFile(fileType: STHeader.FileType, oreginalUrl: URL, thumbImageData: Data, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, creationDate: Date?, modificationDate: Date?) throws -> STLibrary.File {
            
            guard let publicKey = self.album.albumMetadata?.publicKey else {
                throw STFileUploader.UploaderError.fileNotFound
            }
            let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(oreginalUrl: oreginalUrl, thumbImage: thumbImageData, fileType: fileType, duration: duration, toUrl: toUrl, toThumbUrl: toThumbUrl, fileSize: fileSize, publicKey: publicKey)
            let version = "\(STCrypto.Constants.CurrentFileVersion)"
            let dateCreated = creationDate ?? Date()
            let dateModified = modificationDate ?? Date()
            
            let file = try STLibrary.AlbumFile(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false, albumId: self.album.albumId, managedObjectID: nil)
            file.updateIfNeeded(albumMetadata: self.album.albumMetadata)
            return file
        }
        
    }
    
}

private extension PHAsset {
        
    private static let phManager = PHImageManager.default()
    
    struct PHAssetDataInfo {
        var url: URL
        var videoDuration: TimeInterval
        var fileSize: UInt
        var creationDate: Date?
        var modificationDate: Date?
    }

    func requestGetURL(in queue: DispatchQueue?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        if self.mediaType == .image {
            self.requestGetImageAssetDataInfo(in: queue, completion: completion)
        } else if self.mediaType == .video {
            self.requestGetVideoAssetDataInfo(in: queue, completion: completion)
        }
    }
    
    func requestGetThumb(in queue: DispatchQueue?, completion : @escaping ((_ image: UIImage?) -> Void)) {
        let options = PHImageRequestOptions()
        options.version = .current
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let size = STConstants.thumbSize(for: CGSize(width: self.pixelWidth, height: self.pixelHeight))
        Self.phManager.requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: options) { thumb, info  in
            
            if let queue = queue {
                queue.async {
                    completion(thumb)
                }
            } else {
                completion(thumb)
            }
           
        }
    }
    
    //MARK: - Private
    
    private func requestGetVideoAssetDataInfo(in queue: DispatchQueue?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        
        func complet(info: PHAssetDataInfo?) {
            if let queue = queue {
                queue.async {
                    completion(info)
                }
            } else {
                completion(info)
            }
        }
        
        guard self.mediaType == .video else {
            complet(info: nil)
            return
        }
        
        let options: PHVideoRequestOptions = PHVideoRequestOptions()

        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let modificationDate = self.modificationDate ?? self.creationDate
        let creationDate = self.creationDate ?? self.modificationDate

        Self.phManager.requestAVAsset(forVideo: self, options: options, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            
            if let urlAsset = asset as? AVURLAsset, let fileSize = urlAsset.fileSize {
                let localVideoUrl: URL = urlAsset.url as URL
                let responseURL: URL = localVideoUrl
                let videoDuration: TimeInterval = urlAsset.duration.seconds
                let fileSize: UInt = UInt(fileSize)
                let result = PHAssetDataInfo(url: responseURL,
                                videoDuration: videoDuration,
                                fileSize: fileSize,
                                creationDate: creationDate,
                                modificationDate: modificationDate)
                
                complet(info: result)
            } else {
                complet(info: nil)
            }
        })
    }
    
    private func requestGetImageAssetDataInfo(in queue: DispatchQueue?, completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        
        func complet(info: PHAssetDataInfo?) {
            if let queue = queue {
                queue.async {
                    completion(info)
                }
            } else {
                completion(info)
            }
        }
        
        guard self.mediaType == .image else {
            complet(info: nil)
            return
        }
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
            return false
        }
                
        let modificationDate = self.modificationDate ?? self.creationDate
        let creationDate = self.creationDate ?? self.modificationDate
        
        self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
            guard let contentEditingInput = contentEditingInput, let fullSizeImageURL = contentEditingInput.fullSizeImageURL else {
                complet(info: nil)
                return
            }
            let responseURL: URL = fullSizeImageURL
            let videoDuration: TimeInterval = .zero
            let creationDate: Date? = creationDate
            let modificationDate: Date? = modificationDate
            
            let attr = try? FileManager.default.attributesOfItem(atPath: responseURL.path)
            let fileSize = (attr?[FileAttributeKey.size] as? UInt) ?? 0
            
            let result = PHAssetDataInfo(url: responseURL,
                            videoDuration: videoDuration,
                            fileSize: fileSize,
                            creationDate: creationDate,
                            modificationDate: modificationDate)
            complet(info: result)
        })
        
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
