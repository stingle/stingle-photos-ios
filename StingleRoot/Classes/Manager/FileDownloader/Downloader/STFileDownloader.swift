//
//  STFileDownloader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/13/21.
//

import Foundation

public protocol STFileDownloaderObserver: AnyObject {
    
    func downloader(didStartDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource)
    func downloader(didEndDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource)
    func downloader(didFailDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource)
    func downloader(didUpdedProgress downloader: STDownloaderManager.FileDownloader)
    func downloader(didFinished downloader: STDownloaderManager.FileDownloader)
    
}

public extension STFileDownloaderObserver {
    
    func downloader(didStartDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didEndDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didFailDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didChangeProgress downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didUpdedProgress downloader: STDownloaderManager.FileDownloader) {}
    func downloader(didFinished downloader: STDownloaderManager.FileDownloader) {}
    
}


public extension STDownloaderManager {
        
    class FileDownloader: Downloader<STDownloaderManager.DiskCacheObject> {
        
        private let diskCache = DownloaderDiskCache()
        private let memoryCache = MemoryCache()
        
        private let observerEvents = STObserverEvents<STFileDownloaderObserver>()
        private(set) var progressesCount = 0
        private var progresses = [String: Double]()
        
        //MARK: Override
        
        @discardableResult public override func download(source: IDownloaderSource, success: STDownloaderManager.RetryerSuccess<STDownloaderManager.DiskCacheObject>?, progress: STDownloaderManager.RetryerProgress?, failure: STDownloaderManager.RetryerFailure?) -> String {
            super.download(source: source, success: success, progress: progress, failure: failure)
        }
        
        override func createOperation(for source: IDownloaderSource) -> STDownloaderManager.DownloaderOperation<STDownloaderManager.DiskCacheObject> {
            let operation = DownloaderOperation(request: source, memoryCache: self.memoryCache, diskCache: self.diskCache) {(_) in } progress: { (_) in } failure: { (_) in }
            return operation
        }
        
        //MARK: public
        
        public func download(sources: [IDownloaderSource]) {
            self.progressesCount = self.progressesCount + sources.count
            let queue = DispatchQueue.main
            sources.forEach { source in
                queue.async { [weak self] in
                    if self?.progresses[source.identifier] == nil {
                        self?.progresses[source.identifier] = 0
                    }
                    self?.didStartDownload(source: source)
                }
                self.download(source: source) { [weak self] _ in
                    queue.async {
                        self?.progresses[source.identifier] = 1
                        self?.didEndDownload(source: source)
                    }
                } progress: { [weak self] progress in
                    queue.async {
                        self?.progresses[source.identifier] = progress.fractionCompleted
                        self?.didChangeProgress(source: source)
                    }
                    
                } failure: { [weak self] error in
                    queue.async {
                        self?.progresses[source.identifier] = 1
                        self?.didFailDownload(source: source)
                    }
                }
            }
        }
        
        public func download(files: [ILibraryFile]) {
            var sources = [FileDownloaderSource]()
            files.forEach { file in
                if let fileOreginalUrl = file.fileOreginalUrl {
                    let source = FileDownloaderSource(file: file, fileSaveUrl: fileOreginalUrl, isThumb: false)
                    sources.append(source)
                }
            }
            self.download(sources: sources)
        }
        
        public func add(_ listener: STFileDownloaderObserver) {
            self.observerEvents.addObject(listener)
        }
        
        public func remove(_ listener: STFileDownloaderObserver) {
            self.observerEvents.removeObject(listener)
        }
        
        public func hasProgress() -> Bool {
            return self.progressesCount != .zero
        }
        
        public func progress() -> Double {
            let count = self.progresses.count
            var allProgress: Double = 0
            for progresse in self.progresses {
                allProgress = allProgress + progresse.value
            }
            let result = count != .zero ? allProgress / Double(count) : .zero
            return result
        }
        
        //MARK: - Private
        
        private func updateFinished() {
            if self.hasProgress() == false {
                self.observerEvents.forEach { observ in
                    observ.downloader(didFinished: self)
                }
            }
        }
        
        private func didStartDownload(source: IDownloaderSource) {
            self.observerEvents.forEach { observ in
                observ.downloader(didStartDownload: self, source: source)
            }
            self.didUpdedProgress()
        }
        
        private func didEndDownload(source: IDownloaderSource) {
            self.progressesCount = self.progressesCount - 1
            self.observerEvents.forEach { observ in
                observ.downloader(didEndDownload: self, source: source)
            }
            if self.progressesCount == .zero {
                self.updateFinished()
            }
        }
        
        private func didFailDownload(source: IDownloaderSource) {
            self.progressesCount = self.progressesCount - 1
            if self.progressesCount == .zero {
                self.updateFinished()
            }
            self.observerEvents.forEach { observ in
                observ.downloader(didFailDownload: self, source: source)
            }
            self.didUpdedProgress()
            if self.progressesCount == .zero {
                self.updateFinished()
            }
        }
        
        private func didChangeProgress(source: IDownloaderSource) {
            self.observerEvents.forEach { observ in
                observ.downloader(didChangeProgress: self, source: source)
            }
            self.didUpdedProgress()
        }
        
        private func didUpdedProgress() {
            if self.progressesCount == .zero {
                self.progresses.removeAll()
            }
            self.observerEvents.forEach { observ in
                observ.downloader(didUpdedProgress: self)
            }
        }
        
    }
    
    class DiskCacheObject: IDiskCacheObject {
        
        let fileName: String
        
        init(fileName: String) {
            self.fileName = fileName
        }
    }
    
    class DownloaderDiskCache: STDownloaderManager.DiskCache<STDownloaderManager.DiskCacheObject> {
        
        override func createObject(from data: Data, source: IDownloaderSource) throws -> STDownloaderManager.DiskCacheObject {
            return STDownloaderManager.DiskCacheObject(fileName: source.fileName)
        }
        
    }
    
    struct FileDownloaderSource {
        
        public let file: ILibraryFile
        public let fileSaveUrl: URL
        public let isThumb: Bool
        
        public init(file: ILibraryFile, fileSaveUrl: URL, isThumb: Bool) {
            self.file = file
            self.fileSaveUrl = fileSaveUrl
            self.isThumb = isThumb
        }
    }
            
}

extension STDownloaderManager.FileDownloaderSource: STDownloadRequest {
   
    public var fileName: String {
        return self.file.file
    }

    public var parameters: [String : Any]? {
        let isThumbStr = self.isThumb ? "1" : "0"
        let dbSet = "\(self.file.dbSet.rawValue)"
        var params = ["file": self.file.file, "set": dbSet, "is_thumb": isThumbStr]
        params.addIfNeeded(key: "token", value: self.token)
        params.addIfNeeded(key: "albumId", value: self.token)
        if let albumFile = self.file as? STLibrary.AlbumFile {
            params["albumId"] = "\(albumFile.albumId)"
        }
        
        return params
    }

    public var path: String {
        return "sync/downloadRedir"
    }

    public var method: STNetworkDispatcher.Method {
        .post
    }

    public var headers: [String : String]? {
        return nil
    }

    public var encoding: STNetworkDispatcher.Encoding {
        return STNetworkDispatcher.Encoding.body
    }
    
    public var fileDownloadTmpUrl: URL? {
        return self.fileTmpUrl
    }

}

extension STDownloaderManager.FileDownloaderSource: IDownloaderSource {
    
    public var identifier: String {
        return "\(self.fileSaveUrl.path)_\(self.fileName)"
    }
    
    public var fileTmpUrl: URL {
        return self.fileSaveUrl
    }
    
}
