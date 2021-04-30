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

protocol IFileUploaderObserver: AnyObject {
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [STLibrary.File])
    func fileUploader(didEndSucces uploader: STFileUploader, file: STLibrary.File, uploadInfo: STFileUploader.UploadInfo)
    func fileUploader(didEndFailed uploader: STFileUploader, file: STLibrary.File?, error: IError, uploadInfo: STFileUploader.UploadInfo)
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo)
}

extension IFileUploaderObserver {
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [STLibrary.File]) {}
    func fileUploader(didEndSucces uploader: STFileUploader, file: STLibrary.File, uploadInfo: STFileUploader.UploadInfo) {}
    func fileUploader(didEndFailed uploader: STFileUploader, file: STLibrary.File?, error: IError, uploadInfo: STFileUploader.UploadInfo) {}
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo) {}
}

class STFileUploader {
        
    private let dispatchQueue = DispatchQueue(label: "Uploader.queue", attributes: .concurrent)
    private let operationManager = STOperationManager.shared
    
    private var countAllFiles: Int64 = 0
    private var totalCompletedUnitCount: Int64 = 0
    private var observer = STObserverEvents<IFileUploaderObserver>()
    
    private(set) var progresses = [String: Progress]()
    private(set) var uploadedFiles = [STLibrary.File]()
    private(set) var uploadingFiles = [STLibrary.File]()
    let maxCountUploads = 10
    let maxCountYpdateDB = 5
    
    var isUploading: Bool {
        return !self.uploadingFiles.isEmpty
    }
    
    lazy private var operationQueue: STOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: self.maxCountUploads, qualityOfService: .background, underlyingQueue: dispatchQueue)
        return queue
    }()
    
    func upload(files: [IUploadFile]) {
        for file in files {
            self.upload(file: file)
        }
        self.countAllFiles = self.countAllFiles + Int64(files.count)
        self.updateProgress(files: [])
    }
    
    func upload(file: IUploadFile) {
        let operation = Operation(file: file, delegate: self)
        self.operationManager.run(operation: operation, in: self.operationQueue)
    }
    
    func uploadAllLocalFiles() {
        DispatchQueue.main.async { [weak self] in
            let localFiles = STApplication.shared.dataBase.galleryProvider.fetchObjects(format: "isRemote == false")
            self?.dispatchQueue.sync {
                self?.uploadAllLocalFilesInQueue(files: localFiles)
            }
        }
    }
    
    func cancelUploadIng(for file: STLibrary.File) {
     
        for operation in self.operationQueue.allOperations() {
            if let operation = operation as? Operation, operation.libraryFile?.identifier == file.identifier {
                operation.cancel()
                break
            }
            
        }
        
    }
        
    func addListener(_ listener: IFileUploaderObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObserver(_ listener: IFileUploaderObserver) {
        self.observer.removeObject(listener)
    }
    
    // MARK: - private
    
    private func uploadAllLocalFilesInQueue(files: [STLibrary.File]) {
        guard self.checkCanUploadFiles() else {
            return
        }
        files.forEach { (file) in
            if !self.uploadingFiles.contains(where: { file.file == $0.file }) {
                self.uploadingFiles.append(file)
                let operation = Operation(file: file, delegate: self)
                self.operationManager.run(operation: operation, in: self.operationQueue)
            }
        }
        self.countAllFiles = self.countAllFiles + Int64(files.count)
        self.updateProgress(files: [])
    }
    
    private func culculateProgress() -> UploaderProgress {
        var total: Int64 = 0
        var current: Int64 = 0
        var totalFractionCompleted: Double = .zero
        
        let proccessTotalCompletedUnitCount = self.totalCompletedUnitCount
        let oldTotalUnitCount = self.totalCompletedUnitCount + self.countAllFiles
        self.totalCompletedUnitCount = self.countAllFiles == .zero ? .zero : self.totalCompletedUnitCount
        let totalUnitCount = proccessTotalCompletedUnitCount + self.countAllFiles
        
        self.progresses.forEach({
            total = total + ($0.value.totalUnitCount)
            current = current + ($0.value.completedUnitCount)
            let fractionCompleted = total > .zero ? Double(current) / Double(total) : .zero
            totalFractionCompleted = totalFractionCompleted + fractionCompleted
        })
        totalFractionCompleted = totalFractionCompleted + Double(proccessTotalCompletedUnitCount)
        
        let fractionCompleted: Double = totalUnitCount == .zero ? .zero: totalFractionCompleted / Double(totalUnitCount)
        let progress = UploaderProgress(totalUnitCount: total, completedUnitCount: current, fractionCompleted: fractionCompleted, totalCompleted: proccessTotalCompletedUnitCount, count: oldTotalUnitCount)
        
        return progress
    }
    
    private func checkCanUploadFiles() -> Bool {
        let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
        guard let spaceQuota = dbInfo.spaceQuota, let spaceUsed = dbInfo.spaceUsed, Double(spaceUsed) ?? 0 < Double(spaceQuota) ?? 0 else {
            return false
        }
        return true
    }
        
    private func updateDB(file: STLibrary.File) {
        var uploadFiles = self.uploadedFiles
        if !uploadFiles.contains(where: { $0.file == file.file }) {
            uploadFiles.append(file)
        }
        if uploadFiles.count > self.maxCountYpdateDB || self.countAllFiles == 0 {
            uploadFiles.removeAll()
        }
        self.uploadedFiles = uploadFiles
        STApplication.shared.dataBase.galleryProvider.add(models: [file], reloadData: file.isRemote || self.uploadedFiles.isEmpty)
    }
    
}

extension STFileUploader {
    
    private func updateProgress(files: [STLibrary.File]) {
        let uploadInfo = self.generateUploadInfo()
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.observer.forEach { (observer) in
                observer.fileUploader(didUpdateProgress: weakSelf, uploadInfo: uploadInfo, files: files)
            }
            weakSelf.updateProgress(didChange: uploadInfo)
        }
    }
        
    private func updateProgress(didEndSucces file: STLibrary.File) {
        let uploadInfo = self.generateUploadInfo()
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.observer.forEach { (observer) in
                observer.fileUploader(didEndSucces: weakSelf, file: file, uploadInfo: uploadInfo)
            }
            weakSelf.updateProgress(didChange: uploadInfo)
        }
    }
    
    private func updateProgress(didEndFailed file: STLibrary.File?, error: IError) {
        let uploadInfo = self.generateUploadInfo()
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.observer.forEach { (observer) in
                observer.fileUploader(didEndFailed: weakSelf, file: file, error: error, uploadInfo: uploadInfo)
            }
            weakSelf.updateProgress(didChange: uploadInfo)
        }
        
    }
    
    private func updateProgress(didChange uploadInfo: UploadInfo) {
        self.observer.forEach { (observer) in
            observer.fileUploader(didChanged: self, uploadInfo: uploadInfo)
        }
    }
    
    private func generateUploadInfo() -> UploadInfo {
        let uploadFiles = [STLibrary.File](self.uploadedFiles)
        let progresses: [String: Progress] = self.progresses
        let progress = self.culculateProgress()
        return UploadInfo(uploadFiles: uploadFiles,
                          progresses: progresses,
                          progress: progress)
    }
    
}

extension STFileUploader: STFileUploaderOperationDelegate {
    
    func fileUploaderOperation(didStart operation: STFileUploader.Operation) {}
    
    func fileUploaderOperation(didStartUploading operation: STFileUploader.Operation, file: STLibrary.File) {
                
        self.dispatchQueue.async { [weak self] in
            if !(self?.uploadingFiles.contains(where: { file.file == $0.file }) ?? false) {
                self?.uploadingFiles.append(file)
            }
            self?.updateDB(file: file)
            self?.updateProgress(files: [file])
        }
    }
    
    func fileUploaderOperation(didProgress operation: STFileUploader.Operation, progress: Progress, file: STLibrary.File) {
        self.dispatchQueue.sync { [weak self] in
            self?.progresses[file.file] = progress
            self?.updateProgress(files: [file])
        }
    }
    
    func fileUploaderOperation(didEndFailed operation: STFileUploader.Operation, error: IError, file: STLibrary.File?) {
        self.dispatchQueue.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            if let file = file, let index = weakSelf.uploadingFiles.firstIndex(where: { $0.file == file.file }) {
                weakSelf.uploadingFiles.remove(at: index)
            }
            
            weakSelf.totalCompletedUnitCount = weakSelf.totalCompletedUnitCount + 1
            weakSelf.countAllFiles = weakSelf.countAllFiles - 1
           
            guard let file = file else {
                return
            }
            weakSelf.progresses.removeValue(forKey: file.file)
            weakSelf.updateDB(file: file)
            weakSelf.updateProgress(didEndFailed: file, error: error)
        }
    }
    
    func fileUploaderOperation(didEndSucces operation: Operation, file: STLibrary.File, spaceUsed: STDBUsed) {
        self.dispatchQueue.sync { [weak self] in
            guard let weakSelf = self else {
                return
            }
            if let index = weakSelf.uploadingFiles.firstIndex(where: { $0.file == file.file }) {
                weakSelf.uploadingFiles.remove(at: index)
            }
            weakSelf.totalCompletedUnitCount = weakSelf.totalCompletedUnitCount + 1
            weakSelf.countAllFiles = weakSelf.countAllFiles - 1
            weakSelf.progresses.removeValue(forKey: file.file)
            
            let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
            dbInfo.update(with: spaceUsed)
            STApplication.shared.dataBase.dbInfoProvider.update(model: dbInfo)
            weakSelf.updateDB(file: file)
            weakSelf.updateProgress(didEndSucces: file)
        }
    }
    
}

extension STFileUploader {
    
    var isProgress: Bool {
        return self.countAllFiles != 0
    }

}

extension STFileUploader {
    
    struct UploadInfo {
        let uploadFiles: [STLibrary.File]
        let progresses: [String: Progress]
        let progress: UploaderProgress
    }
    
    enum FileType: Int {
        case unknown = 0
        case image = 1
        case video = 2
        case audio = 3
    }
    
    enum UploaderError: IError {
        case phAssetNotValid
        case fileSystemNotValid
        case wrongStorageSize
        case fileNotFound
        case error(error: Error)
        
        var message: String {
            switch self {
            case .phAssetNotValid:
                return "empty_data".localized
            case .fileSystemNotValid:
                return "nework_error_request_not_valed".localized
            case .wrongStorageSize:
                return "storage_size_isover".localized
            case .fileNotFound:
                return "error_data_not_found".localized
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
    
    struct UploaderProgress {
        let totalUnitCount: Int64
        let completedUnitCount: Int64
        let fractionCompleted: Double
        
        let totalCompleted: Int64
        let count: Int64
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
