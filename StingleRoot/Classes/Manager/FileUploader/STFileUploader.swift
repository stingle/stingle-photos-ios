//
//  STFileUploader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation

public protocol IFileUploaderObserver: AnyObject {
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [ILibraryFile])
    func fileUploader(didEndSucces uploader: STFileUploader, file: ILibraryFile, uploadInfo: STFileUploader.UploadInfo)
    func fileUploader(didEndFailed uploader: STFileUploader, file: ILibraryFile?, error: IError, uploadInfo: STFileUploader.UploadInfo)
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo)
}

public extension IFileUploaderObserver {
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [ILibraryFile]) {}
    func fileUploader(didEndSucces uploader: STFileUploader, file: ILibraryFile, uploadInfo: STFileUploader.UploadInfo) {}
    func fileUploader(didEndFailed uploader: STFileUploader, file: ILibraryFile?, error: IError, uploadInfo: STFileUploader.UploadInfo) {}
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo) {}
}

public class STFileUploader {
        
    private let dispatchQueue = DispatchQueue(label: "Uploader.queue", attributes: .concurrent)
    private let operationManager = STOperationManager.shared
    
    private var countAllFiles = [STLibrary.DBSet: Int64]()
    private var totalCompletedUnitCount: Int64 = 0
    private var observer = STObserverEvents<IFileUploaderObserver>()
    
    private(set) var uploadedFiles = [STLibrary.DBSet: [ILibraryFile]]()

    // Successfully-uploaded files whose isRemote/isSynched flip hasn't been written to Core Data yet,
    // accumulated per DB set so the writes can be flushed in batches (see `updateDB`).
    private var pendingDBUpdateFiles = [STLibrary.DBSet: [ILibraryFile]]()

    private var progresses = [String: Progress]()
    private var uploadingFiles = [ILibraryFile]()

    // Thread-safe, synchronously-readable mirror of `!uploadingFiles.isEmpty`. The gallery data source
    // reads `isUploading` on the MAIN thread (in `STCollectionViewDataSource.didChangeContent`) to skip
    // diff *animations* while an upload is in flight: the animated apply of the full-library diffable
    // snapshot is the visible per-upload hitch (~0.5s animated vs ~0.08s non-animated on a large
    // library). `uploadingFiles` is only safe to read on the barrier `dispatchQueue`, so the boolean is
    // mirrored here under a lock and republished (`refreshUploadingState`) after every mutation.
    //
    // The flag is *debounced off*: when the last file drains it stays true for `uploadSettleDelay`. The
    // final batch's flush -> backgroundContext save -> viewContext auto-merge -> gallery applySnapshot
    // happens just AFTER `uploadingFiles` empties, so clearing the flag synchronously made that last
    // reload animate (the residual per-upload freeze). A new upload within the window cancels the clear.
    private let uploadingStateLock = NSLock()
    private var _isUploading = false
    private var uploadIdleWorkItem: DispatchWorkItem?
    private let uploadSettleDelay: TimeInterval = 2.0
    public var isUploading: Bool {
        self.uploadingStateLock.lock()
        defer { self.uploadingStateLock.unlock() }
        return self._isUploading
    }

    let maxCountUploads = 100
    let maxCountUpdateDB = 5
    
    public private(set) var updateDBChanges  = [String: Int]()
    
    lazy private var operationQueue: STOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: self.maxCountUploads, qualityOfService: .background, underlyingQueue: self.dispatchQueue)
        return queue
    }()
        
    public func getProgress(_ progresses: @escaping(_ progresses: [String: Progress], _ uploadingFiles: [ILibraryFile]) -> Void) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self else { return }
            progresses(weakSelf.progresses, weakSelf.uploadingFiles)
        }
    }
    
    public func isProgress(hendler: @escaping(Bool) -> Void) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self else { return }
            hendler(!weakSelf.uploadingFiles.isEmpty)
        }
    }
    
    public func upload(files: [ILibraryFile]) {
        self.uploadAllLocalFilesInQueue(files: files)
    }
    
    @discardableResult public func upload(files: [STImporter.GaleryFileAssetImportable]) -> STImporter.GaleryAssetFileImporter {
        let importer = STImporter.GaleryFileImporter(importFiles: files, responseQueue: self.dispatchQueue, startHendler: {}, progressHendler: { progress in }) { [weak self] files, importableFiles in
            self?.uploadAllLocalFilesInQueue(files: files)
        }
        return importer
    }
    
    @discardableResult public func uploadAlbum(files: [STImporter.AlbumFileAssetImportable], album: STLibrary.Album) -> STImporter.AlbumAssetFileImporter {
        let importer = STImporter.AlbumFileImporter(album: album, importFiles: files, responseQueue: self.dispatchQueue, startHendler: {}, progressHendler: { progress in }) { [weak self]  files, importableFiles in
            self?.uploadAllLocalFilesInQueue(files: files)
        }
        return importer
    }
    
    public func uploadAllLocalFiles() {
        // Runs from `didEndSync` on the main thread after *every* sync. Do the `canUploadFile()`
        // guard (and the `getLocalFiles()` DB fetch) on the background queue so the upload path adds
        // no main-thread work to a sync — including the cold-launch case where the user record isn't
        // cached yet and the guard would otherwise fetch it on main.
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self, STApplication.shared.utils.canUploadFile() else {
                return
            }
            let files = weakSelf.getLocalFiles()
            weakSelf.uploadAllLocalFilesInQueue(files: files)
        }
    }
    
    public func cancelUploadIng(for files: [ILibraryFile]) {
        files.forEach { file in
            self.cancelUploadIng(for: file)
        }
    }
    
    public func cancelUploadIng(for file: ILibraryFile) {
        for operation in self.operationQueue.allOperations() {
            if let operation = operation as? IFileUploaderOperation, operation.fileIdentifier == file.identifier {
                operation.cancel()
                break
            }
        }
    }
        
    public func addListener(_ listener: IFileUploaderObserver) {
        self.observer.addObject(listener)
    }
    
    public func removeObserver(_ listener: IFileUploaderObserver) {
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
            files.forEach { (file) in
                if !weakSelf.uploadingFiles.contains(where: { file.file == $0.file }) {
                    weakSelf.uploadingFiles.append(file)
                    
                    switch file.dbSet {
                    case .none:
                        break
                    case .galery:
                        let operation = Operation<STLibrary.GaleryFile>(file: file as! STLibrary.GaleryFile, delegate: weakSelf)
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                    case .trash:
                        let operation = Operation<STLibrary.TrashFile>(file: file as! STLibrary.TrashFile, delegate: weakSelf)
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                    case .album:
                        let operation = Operation<STLibrary.AlbumFile>(file: file as! STLibrary.AlbumFile, delegate: weakSelf)
                        weakSelf.operationManager.run(operation: operation, in: weakSelf.operationQueue)
                    }
                    weakSelf.countAllFiles[file.dbSet] = (weakSelf.countAllFiles[file.dbSet] ?? .zero) + 1
                }
            }
            weakSelf.refreshUploadingState()
            weakSelf.updateProgress(files: files)
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
        
    /// Recompute the synchronously-readable `isUploading` flag from `uploadingFiles`. MUST be called on
    /// the barrier `dispatchQueue` (where `uploadingFiles` is mutated). Raising is immediate; clearing
    /// is debounced by `uploadSettleDelay` so the final batch's auto-merge reload still counts as
    /// upload-driven (and is applied without animation).
    private func refreshUploadingState() {
        if !self.uploadingFiles.isEmpty {
            self.uploadIdleWorkItem?.cancel()
            self.uploadIdleWorkItem = nil
            self.setIsUploading(true)
        } else if self.uploadIdleWorkItem == nil {
            let work = DispatchWorkItem(flags: .barrier) { [weak self] in
                self?.uploadIdleWorkItem = nil
                self?.setIsUploading(false)
            }
            self.uploadIdleWorkItem = work
            self.dispatchQueue.asyncAfter(deadline: .now() + self.uploadSettleDelay, execute: work)
        }
    }

    private func setIsUploading(_ value: Bool) {
        self.uploadingStateLock.lock()
        self._isUploading = value
        self.uploadingStateLock.unlock()
    }

    private func updateDB(file: ILibraryFile, updateDB: Bool) {
        var uploadFiles = self.uploadedFiles[file.dbSet] ?? [ILibraryFile]()
        if !uploadFiles.contains(where: { $0.file == file.file }) {
            uploadFiles.append(file)
        }
        if uploadFiles.count >= self.maxCountUpdateDB || self.countAllFiles[file.dbSet] == 0 {
            uploadFiles.removeAll()
        }
        self.uploadedFiles[file.dbSet] = uploadFiles
        let updateDB = updateDB
        guard updateDB else {
            return
        }
        // Batch the gallery/trash/album DB writes. Each `provider.update(models:)` does a
        // backgroundContext `save()` that the main `viewContext` auto-merges (it has
        // `automaticallyMergesChangesFromParent = true`), and that merge fires the gallery FRC, which
        // rebuilds the full diffable snapshot (O(library)) on the MAIN thread. Doing it once per
        // uploaded file made the UI hitch on *every* file. Accumulate the successfully-uploaded files
        // and flush them through a single `update(models:)` per batch (every `maxCountUpdateDB`, and a
        // final flush when the whole upload drains — see the completion handlers), so the FRC fires
        // per batch, not per file. Persistence of isRemote/isSynched lags by < a batch; a mid-upload
        // kill self-heals because the next launch's sync reconciles already-uploaded files before
        // `uploadAllLocalFiles` would re-send them.
        var pending = self.pendingDBUpdateFiles[file.dbSet] ?? [ILibraryFile]()
        if !pending.contains(where: { $0.file == file.file }) {
            pending.append(file)
        }
        self.pendingDBUpdateFiles[file.dbSet] = pending
        if pending.count >= self.maxCountUpdateDB {
            self.flushPendingDBUpdates(for: file.dbSet)
        }
    }

    // Writes one accumulated batch of uploaded files to Core Data in a single `update(models:)`
    // (one backgroundContext save → one FRC reload), instead of one save per file.
    private func flushPendingDBUpdates(for dbSet: STLibrary.DBSet) {
        guard let pending = self.pendingDBUpdateFiles[dbSet], !pending.isEmpty else {
            return
        }
        self.pendingDBUpdateFiles[dbSet] = []
        let reload = pending.allSatisfy { $0.isRemote && $0.isSynched }
        #if DEBUG
        NSLog("[STPERF] flushPendingDBUpdates dbSet=%d count=%d reload=%d", dbSet.rawValue, pending.count, reload ? 1 : 0)
        #endif
        switch dbSet {
        case .album:
            let models = pending.compactMap { $0 as? STLibrary.AlbumFile }
            STApplication.shared.dataBase.albumFilesProvider.update(models: models, reloadData: reload)
        case .trash:
            let models = pending.compactMap { $0 as? STLibrary.TrashFile }
            STApplication.shared.dataBase.trashProvider.update(models: models, reloadData: reload)
        case .galery:
            let models = pending.compactMap { $0 as? STLibrary.GaleryFile }
            // reloadData: false on purpose. `update(models:)` still does a backgroundContext `save()`,
            // which the main `viewContext` auto-merges (automaticallyMergesChangesFromParent), and that
            // merge drives the gallery FRC to reload exactly the changed cells (it marks the
            // isRemote/isSynched flip as an update). Passing reloadData: true would *additionally* run a
            // full-catalog `performFetch` (O(library), ~0.5s on a large library) on the main thread to
            // surface the very same change — pure redundancy, and the residual per-upload freeze.
            // Nothing observes the gallery provider's `didUpdated`, so dropping that notification is
            // safe. (Album/trash keep `reload`: STAlbumsDataSource observes albumFilesProvider.)
            STApplication.shared.dataBase.galleryProvider.update(models: models, reloadData: false)
        case .none:
            break
        }
    }

    // Flush every remaining partial batch. Called when the whole upload drains (`uploadingFiles` is
    // empty) from both the success and failure handlers, so a trailing batch smaller than
    // `maxCountUpdateDB` — or one left behind when the last file failed — is never stranded.
    private func flushAllPendingDBUpdates() {
        Array(self.pendingDBUpdateFiles.keys).forEach { dbSet in
            self.flushPendingDBUpdates(for: dbSet)
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
        var uploadFiles = [ILibraryFile]()
        self.uploadedFiles.forEach { keyValue in
            uploadFiles.append(contentsOf: keyValue.value)
        }
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
            self?.refreshUploadingState()
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
            weakSelf.refreshUploadingState()
            weakSelf.totalCompletedUnitCount = weakSelf.totalCompletedUnitCount + 1
            guard let file = file else {
                return
            }
            weakSelf.countAllFiles[file.dbSet] = (weakSelf.countAllFiles[file.dbSet] ?? .zero) - 1
            weakSelf.progresses.removeValue(forKey: file.file)
            weakSelf.updateDB(file: file, updateDB: false)
            if weakSelf.uploadingFiles.isEmpty {
                weakSelf.flushAllPendingDBUpdates()
            }
            weakSelf.updateProgress(didEndFailed: file, error: error)
        }
    }
    
    func fileUploaderOperation(didEndSucces operation: IFileUploaderOperation, file: ILibraryFile, spaceUsed: STDBUsed?) {
        
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            #if DEBUG
            NSLog("[STPERF] ==== upload didEndSucces file=%@ remaining=%d ====", file.file, weakSelf.uploadingFiles.count - 1)
            #endif
            if let index = weakSelf.uploadingFiles.firstIndex(where: { $0.file == file.file }) {
                weakSelf.uploadingFiles.remove(at: index)
            }
            weakSelf.refreshUploadingState()
            weakSelf.totalCompletedUnitCount = weakSelf.totalCompletedUnitCount + 1
            weakSelf.countAllFiles[file.dbSet] = (weakSelf.countAllFiles[file.dbSet] ?? .zero) - 1
            weakSelf.progresses.removeValue(forKey: file.file)

            if let spaceUsed = spaceUsed {
                let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
                dbInfo.update(with: spaceUsed)
                STApplication.shared.dataBase.dbInfoProvider.update(model: dbInfo)
            }
            weakSelf.updateDB(file: file, updateDB: true)
            if weakSelf.uploadingFiles.isEmpty {
                weakSelf.flushAllPendingDBUpdates()
            }
            weakSelf.updateProgress(didEndSucces: file)
        }
                
    }
    
}

extension STFileUploader {
    
    public struct UploadInfo {
        public let uploadFiles: [ILibraryFile]
        public let progresses: [String: Progress]
        public let fractionCompleted: Double
    }
    
    public enum FileType: Int {
        case unknown = 0
        case image = 1
        case video = 2
        case audio = 3
    }
    
    public enum UploaderError: IError {
        case phAssetNotValid
        case fileSystemNotValid
        case wrongStorageSize
        case fileNotFound
        case canceled
        case memoryLow
        case error(error: Error)
        
        public var message: String {
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
