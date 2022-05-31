//
//  STFileUploader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation

protocol IFileUploaderObserver: AnyObject {
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [ILibraryFile])
    func fileUploader(didEndSucces uploader: STFileUploader, file: ILibraryFile, uploadInfo: STFileUploader.UploadInfo)
    func fileUploader(didEndFailed uploader: STFileUploader, file: ILibraryFile?, error: IError, uploadInfo: STFileUploader.UploadInfo)
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo)
}

extension IFileUploaderObserver {
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [ILibraryFile]) {}
    func fileUploader(didEndSucces uploader: STFileUploader, file: ILibraryFile, uploadInfo: STFileUploader.UploadInfo) {}
    func fileUploader(didEndFailed uploader: STFileUploader, file: ILibraryFile?, error: IError, uploadInfo: STFileUploader.UploadInfo) {}
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo) {}
}

class STFileUploader {
        
    private let dispatchQueue = DispatchQueue(label: "Uploader.queue", attributes: .concurrent)
    private let operationManager = STOperationManager.shared
    
    private var countAllFiles: Int64 = 0
    private var totalCompletedUnitCount: Int64 = 0
    private var observer = STObserverEvents<IFileUploaderObserver>()
    
    private(set) var uploadedFiles = [ILibraryFile]()
    
    private var progresses = [String: Progress]()
    private var uploadingFiles = [ILibraryFile]()
    
    let maxCountUploads = 100
    let maxCountUpdateDB = 5
    
    private(set) var updateDBChanges  = [String: Int]()
    
    var isUploading: Bool {
        return !self.uploadingFiles.isEmpty
    }
    
    lazy private var operationQueue: STOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: self.maxCountUploads, qualityOfService: .background, underlyingQueue: self.dispatchQueue)
        return queue
    }()
        
    func getProgress(_ progresses: @escaping(_ progresses: [String: Progress], _ uploadingFiles: [ILibraryFile]) -> Void) {
        self.dispatchQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            progresses(weakSelf.progresses, weakSelf.uploadingFiles)
        }
    }
    
    func upload(files: [ILibraryFile]) {
        self.uploadAllLocalFilesInQueue(files: files)
    }
    
    @discardableResult
    func upload(files: [STImporter.GaleryFileImportable]) -> STImporter.GaleryFileImporter {
        let importer = STImporter.GaleryFileImporter(importFiles: files, responseQueue: self.dispatchQueue, startHendler: {}, progressHendler: { progress in }) { [weak self] files, importableFiles in
            self?.uploadAllLocalFilesInQueue(files: files)
        }
        return importer
    }
    
    @discardableResult
    func uploadAlbum(files: [STImporter.AlbumFileImportable], album: STLibrary.Album) -> STImporter.AlbumFileImporter {
        
        let importer = STImporter.AlbumFileImporter(importFiles: files, album: album, responseQueue: self.dispatchQueue, startHendler: {}, progressHendler: { progress in }) { [weak self] files, importableFiles in
            self?.uploadAllLocalFilesInQueue(files: files)
        }

        return importer
    }
    
    func uploadAllLocalFiles() {
        guard STApplication.shared.utils.canUploadFile() else {
            return
        }
        self.dispatchQueue.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            let files = weakSelf.getLocalFiles()
            weakSelf.uploadAllLocalFilesInQueue(files: files)
        }
    }
    
    func cancelUploadIng(for files: [ILibraryFile]) {
        files.forEach { file in
            self.cancelUploadIng(for: file)
        }
    }
    
    func cancelUploadIng(for file: ILibraryFile) {
        for operation in self.operationQueue.allOperations() {
            if let operation = operation as? IFileUploaderOperation, operation.fileIdentifier == file.identifier {
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
    
    private func getLocalFiles() -> [ILibraryFile] {
        let dataBase = STApplication.shared.dataBase
                
        let localGalleryFiles = dataBase.galleryProvider.getLocalFiles()
        let localAlbumFiles = dataBase.albumFilesProvider.getLocalFiles()
        let trashFiles = dataBase.trashProvider.getLocalFiles()
        
        
        let albumIds: [String] = localAlbumFiles.compactMap( { return $0.albumId } )
        let albums: [STLibrary.Album] = dataBase.albumsProvider.fetchObjects(identifiers: albumIds)
        var albumIdsDic = [String: STLibrary.Album]()
        
        albums.forEach { album in
            albumIdsDic[album.albumId] = album
        }
        
        localAlbumFiles.forEach { albumFile in
            if let album = albumIdsDic[albumFile.albumId] {
                albumFile.updateIfNeeded(albumMetadata: album.albumMetadata)
            }
        }
                
        var localFiles = [ILibraryFile]()
        localFiles.append(contentsOf: localGalleryFiles)
        localFiles.append(contentsOf: localAlbumFiles)
        localFiles.append(contentsOf: trashFiles)
        return localFiles
    }
    
    private func uploadAllLocalFilesInQueue(files: [ILibraryFile]) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self, weakSelf.checkCanUploadFiles() else {
                return
            }
            var filesCount: Int = .zero
            files.forEach { (file) in
                if !weakSelf.uploadingFiles.contains(where: { file.file == $0.file }) {
                    weakSelf.uploadingFiles.append(file)
                    
                    switch file.dbSet {
                    case .none:
                        break
                    case .galery:
                        let operation = Operation<STLibrary.GaleryFile>(file: file as! STLibrary.GaleryFile, delegate: weakSelf)
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                        filesCount = filesCount + 1
                    case .trash:
                        let operation = Operation<STLibrary.TrashFile>(file: file as! STLibrary.TrashFile, delegate: weakSelf)
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                        filesCount = filesCount + 1
                    case .album:
                        let operation = Operation<STLibrary.AlbumFile>(file: file as! STLibrary.AlbumFile, delegate: weakSelf)
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                        filesCount = filesCount + 1
                    }
                }
            }
            
            weakSelf.countAllFiles = weakSelf.countAllFiles + Int64(filesCount)
            weakSelf.updateProgress(files: [])
        }
        
    }
    
    private func culculateProgress() -> Double {
        
        guard !self.progresses.isEmpty else {
            return .zero
        }
        var progress = Double.zero
        self.progresses.forEach {
            progress = progress + $0.value.fractionCompleted
        }
        progress = progress / Double(self.progresses.count)
        return progress

    }
    
    private func checkCanUploadFiles() -> Bool {
        let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
        guard let spaceQuota = dbInfo.spaceQuota, let spaceUsed = dbInfo.spaceUsed, Double(spaceUsed) ?? 0 < Double(spaceQuota) ?? 0 else {
            return false
        }
        return true
    }
        
    private func updateDB(file: ILibraryFile, updateDB: Bool) {
        var uploadFiles = self.uploadedFiles
        if !uploadFiles.contains(where: { $0.file == file.file }) {
            uploadFiles.append(file)
        }
        
        if uploadFiles.count >= self.maxCountUpdateDB || self.countAllFiles == 0 {
            uploadFiles.removeAll()
        }
                        
        self.uploadedFiles = uploadFiles
                
        let updateDB = updateDB
        
        guard updateDB else {
            return
        }

        if file.isRemote {
            if let albumFile = file as? STLibrary.AlbumFile {
                STApplication.shared.dataBase.albumFilesProvider.update(models: [albumFile], reloadData: true)
            } else if let trashFile = file as? STLibrary.TrashFile {
                STApplication.shared.dataBase.trashProvider.update(models: [trashFile], reloadData: true)
            } else if let galeryFile = file as? STLibrary.GaleryFile {
                STApplication.shared.dataBase.galleryProvider.update(models: [galeryFile], reloadData: true)
            }
        }
        
    }
    
}

extension STFileUploader {
    
    private func updateProgress(files: [ILibraryFile]) {
        let uploadInfo = self.generateUploadInfo()
        self.observer.forEach { (observer) in
            observer.fileUploader(didUpdateProgress: self, uploadInfo: uploadInfo, files: files)
        }
        self.updateProgress(didChange: uploadInfo)
    }
        
    private func updateProgress(didEndSucces file: ILibraryFile) {
        let uploadInfo = self.generateUploadInfo()
        self.observer.forEach { (observer) in
            observer.fileUploader(didEndSucces: self, file: file, uploadInfo: uploadInfo)
        }
        self.updateProgress(didChange: uploadInfo)
    }
    
    private func updateProgress(didEndFailed file: ILibraryFile?, error: IError) {
        let uploadInfo = self.generateUploadInfo()
        self.observer.forEach { (observer) in
            observer.fileUploader(didEndFailed: self, file: file, error: error, uploadInfo: uploadInfo)
        }
        self.updateProgress(didChange: uploadInfo)
    }
    
    private func updateProgress(didChange uploadInfo: UploadInfo) {
        self.observer.forEach { (observer) in
            observer.fileUploader(didChanged: self, uploadInfo: uploadInfo)
        }
    }
    
    private func generateUploadInfo() -> UploadInfo {
        let uploadFiles = [ILibraryFile](self.uploadedFiles)
        let progresses: [String: Progress] = self.progresses
        let progress = self.culculateProgress()
        return UploadInfo(uploadFiles: uploadFiles,
                          progresses: progresses,
                          fractionCompleted: progress)
    }
    
}

extension STFileUploader: STFileUploaderOperationDelegate {
    
    func fileUploaderOperation(didStart operation: IFileUploaderOperation) {}
    
    func fileUploaderOperation(didStartUploading operation: IFileUploaderOperation, file: ILibraryFile) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            if !(self?.uploadingFiles.contains(where: { file.file == $0.file }) ?? false) {
                self?.uploadingFiles.append(file)
            }
            self?.updateDB(file: file, updateDB: false)
            self?.updateProgress(files: [file])
        }
    }
    
    func fileUploaderOperation(didProgress operation: IFileUploaderOperation, progress: Progress, file: ILibraryFile) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            self?.progresses[file.file] = progress
            self?.updateProgress(files: [file])
        }
    }
    
    func fileUploaderOperation(didEndFailed operation: IFileUploaderOperation, error: IError, file: ILibraryFile?) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
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
            weakSelf.updateDB(file: file, updateDB: false)
            weakSelf.updateProgress(didEndFailed: file, error: error)
        }
    }
    
    func fileUploaderOperation(didEndSucces operation: IFileUploaderOperation, file: ILibraryFile, spaceUsed: STDBUsed?) {
        
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            if let index = weakSelf.uploadingFiles.firstIndex(where: { $0.file == file.file }) {
                weakSelf.uploadingFiles.remove(at: index)
            }
            weakSelf.totalCompletedUnitCount = weakSelf.totalCompletedUnitCount + 1
            weakSelf.countAllFiles = weakSelf.countAllFiles - 1
            weakSelf.progresses.removeValue(forKey: file.file)
            
            if let spaceUsed = spaceUsed {
                weakSelf.dispatchQueue.async {
                    let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
                    dbInfo.update(with: spaceUsed)
                    STApplication.shared.dataBase.dbInfoProvider.update(model: dbInfo)
                }
            }
                    
            weakSelf.updateDB(file: file, updateDB: true)
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
        let uploadFiles: [ILibraryFile]
        let progresses: [String: Progress]
        let fractionCompleted: Double
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
        case canceled
        case memoryLow
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
            case .canceled:
                return "error_canceled".localized
            case .memoryLow:
                return "error_memory_low".localized
            case .error(let error):
                if let iError = error as? IError {
                    return iError.message
                }
                return error.localizedDescription
            }
        }
    }
        
}
