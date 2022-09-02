//
//  IImportable+PHAsset.swift
//  StingleRoot
//
//  Created by Khoren Asatryan on 12.07.22.
//

import Foundation
import Photos

public protocol IImportablePHAsset: IImportableFile {
    var asset: PHAsset { get }
}

public extension IImportablePHAsset {
    
    func requestData(in queue: DispatchQueue?, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void) {
        
        let mediaType = self.asset.mediaType
        var fileType: STHeader.FileType!
        
        switch mediaType {
        case .image:
            fileType = .image
        case .video:
            fileType = .video
        default:
            STLogger.log(logMessage: "fileType not support")
            fatalError("fileType not support")
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

        func compled(uploadInfo: STImporter.ImportFileInfo) {
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

                let importFileInfo = STImporter.ImportFileInfo(oreginalUrl: info.dataInfo,
                                                                thumbImage: thumbData,
                                                                fileType: fileType,
                                                                duration: info.videoDuration,
                                                                fileSize: info.fileSize,
                                                                creationDate: info.creationDate,
                                                                modificationDate: info.modificationDate,
                                                                freeBuffer: info.freeBuffer)
                compled(uploadInfo: importFileInfo)
            }
        }
    }
    
}

extension STImporter {
            
    public class GaleryFileAssetImportable: IImportablePHAsset, GaleryImportable {
        
        public let asset: PHAsset
        public init(asset: PHAsset) {
            self.asset = asset
        }
        
    }
    
    public class AlbumFileAssetImportable: IImportablePHAsset, AlbumFileImportable {
        
        public let album: STLibrary.Album
        public let asset: PHAsset
       
        public init(asset: PHAsset, album: STLibrary.Album) {
            self.asset = asset
            self.album = album
        }
    }
    
}

public extension AVURLAsset {

    var fileSize: UInt? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        guard let size = resourceValues?.fileSize ?? resourceValues?.totalFileSize else {
            return nil
        }
        return UInt(size)
    }
}
