//
//  STFileUploader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Photos
import UIKit

protocol IUploadFile {
    func requestData(success: @escaping (_ uploadInfo: STFileUploader.UploadFileInfo) -> Void, failure: @escaping (_ failure: IError ) -> Void)
}

class STFileUploader {
        
    private let dispatchQueue = DispatchQueue(label: "Uploader.queue", attributes: .concurrent)
    private let operationManager = STOperationManager.shared
    
    lazy var operationQueue: STOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 10, underlyingQueue: dispatchQueue)
        return queue
    }()
    
    func upload(files: [IUploadFile]) {
        for f in files {
            self.upload(file: f)
        }
    }
    
    
    func upload(file: IUploadFile) {
        let operation = Operation(file: file, delegate: self)
        self.operationManager.run(operation: operation, in: self.operationQueue)
    }
    
}

extension STFileUploader: STFileUploaderOperationDelegate {
    
    func fileUploaderOperation(didStart operation: STFileUploader.Operation) {
        
    }
    
    func fileUploaderOperation(didStartUploading operation: STFileUploader.Operation, file: STLibrary.File) {
        STApplication.shared.dataBase.galleryProvider.add(models: [file])
    }
    
    func fileUploaderOperation(didProgress operation: STFileUploader.Operation, progress: Progress, file: STLibrary.File) {
        
    }
    
    func fileUploaderOperation(didEndFailed operation: STFileUploader.Operation, error: IError, file: STLibrary.File?) {
        
    }
    
    func fileUploaderOperation(didEndSucces operation: Operation, file: STLibrary.File, spaceUsed: STDBUsed) {
        let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
        dbInfo.update(with: spaceUsed)
        STApplication.shared.dataBase.dbInfoProvider.update(model: dbInfo)
        STApplication.shared.dataBase.galleryProvider.add(models: [file])
    }
    
}

extension STFileUploader {
    
    enum FileType: Int {
        case unknown = 0
        case image = 1
        case video = 2
        case audio = 3
    }
    
    enum UploaderError: IError {
        case phAssetNotValid
        case fileSystemNotValid
        case error(error: Error)
        
        var message: String {
            switch self {
            case .phAssetNotValid:
                return "empty_data".localized
            case .fileSystemNotValid:
                return "nework_error_request_not_valed".localized
            case .error(let error):
                if let iError = error as? IError {
                    return iError.message
                }
                return error.localizedDescription
            }
        }
    }
    
    struct UploadFileInfo {
        let oreginalUrl: URL
        let thumbImage: Data
        let fileType: STFileUploader.FileType
        let duration: TimeInterval
        var fileSize: Int32
        var creationDate: Date?
        var modificationDate: Date?
    }
            
}

extension PHAsset: IUploadFile {
    
    func requestData(success: @escaping (_ uploadInfo: STFileUploader.UploadFileInfo) -> Void, failure: @escaping (IError) -> Void) {
        guard let fileType = STFileUploader.FileType(rawValue: self.mediaType.rawValue) else {
            failure(STFileUploader.UploaderError.phAssetNotValid)
            return
        }
        self.requestGetThumb { [weak self] (thumb) in
            guard let thumb = thumb, let thumbData = thumb.pngData() else {
                failure(STFileUploader.UploaderError.phAssetNotValid)
                return
            }
            self?.requestGetURL(completion: { (info) in
                guard let info = info else {
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

private extension PHAsset {
        
    private static let phManager = PHImageManager.default()
    
    struct PHAssetDataInfo {
        var url: URL
        var videoDuration: TimeInterval
        var fileSize: Int32
        var creationDate: Date?
        var modificationDate: Date?
    }

    func requestGetURL(completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        if self.mediaType == .image {
            self.requestGetImageAssetDataInfo(completion: completion)
        } else if self.mediaType == .video {
            self.requestGetVideoAssetDataInfo(completion: completion)
        }
    }
    
    func requestGetThumb(completion : @escaping ((_ image: UIImage?) -> Void)) {
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = false
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let size = STConstants.thumbSize(for: CGSize(width: self.pixelWidth, height: self.pixelHeight))
        Self.phManager.requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: options) { thumb, info  in
            completion(thumb)
        }
    }
    
    //MARK: - Private
    
    private func requestGetVideoAssetDataInfo(completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        guard self.mediaType == .video else {
            completion(nil)
            return
        }
        
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        
        let modificationDate = self.modificationDate
        let creationDate = self.creationDate
        
        Self.phManager.requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            if let urlAsset = asset as? AVURLAsset, let fileSize = urlAsset.fileSize {
                let localVideoUrl: URL = urlAsset.url as URL
                let responseURL: URL = localVideoUrl
                let videoDuration: TimeInterval = urlAsset.duration.seconds
                let fileSize: Int32 = Int32(fileSize)
                let result = PHAssetDataInfo(url: responseURL,
                                videoDuration: videoDuration,
                                fileSize: fileSize,
                                creationDate: creationDate,
                                modificationDate: modificationDate)
                
                completion(result)
            } else {
                completion(nil)
            }
        })
    }
    
    private func requestGetImageAssetDataInfo(completion : @escaping ((_ dataInfo: PHAssetDataInfo?) -> Void)) {
        guard self.mediaType == .image else {
            completion(nil)
            return
        }
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
            return true
        }
        
        let modificationDate = self.modificationDate
        let creationDate = self.creationDate
        
        self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
            guard let contentEditingInput = contentEditingInput, let fullSizeImageURL = contentEditingInput.fullSizeImageURL else {
                completion(nil)
                return
            }
            let responseURL: URL = fullSizeImageURL
            let videoDuration: TimeInterval = .zero
            let creationDate: Date? = creationDate
            let modificationDate: Date? = modificationDate
            
            let attr = try? FileManager.default.attributesOfItem(atPath: responseURL.path)
            let fileSize = (attr?[FileAttributeKey.size] as? Int32) ?? 0
            
            let result = PHAssetDataInfo(url: responseURL,
                            videoDuration: videoDuration,
                            fileSize: fileSize,
                            creationDate: creationDate,
                            modificationDate: modificationDate)
            completion(result)
        })
        
    }
    
}

extension AVURLAsset {
    
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}
