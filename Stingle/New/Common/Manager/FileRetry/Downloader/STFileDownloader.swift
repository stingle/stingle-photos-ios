//
//  STFileDownloader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/13/21.
//

import Foundation

protocol STFileDownloaderObserver: AnyObject {
    
    func downloader(didStaryDownload downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource)
    func downloader(didEndDownload downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource)
    func downloader(didFailDownload downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource)
    func downloader(didUpdedProgress downloader: SDownloaderManager.FileDownloader)
    
}

extension STFileDownloaderObserver {
    
    func downloader(didStaryDownload downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didEndDownload downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didFailDownload downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didChangeProgress downloader: SDownloaderManager.FileDownloader, source: IDownloaderSource) {}
    func downloader(didUpdedProgress downloader: SDownloaderManager.FileDownloader) {}
    
}


extension SDownloaderManager {
        
    class FileDownloader: Downloader<SDownloaderManager.DiskCacheObject> {
        
        private let diskCache = DownloaderDiskCache()
        private let memoryCache = MemoryCache()
        
        private let observerEvents = STObserverEvents<STFileDownloaderObserver>()
        private var progresses = [String: Progress?]()
        
        //MARK: Override
        
        override func createOperation(for source: IDownloaderSource) -> SDownloaderManager.DownloaderOperation<SDownloaderManager.DiskCacheObject> {
            if self.progresses[source.identifier] == nil {
                self.progresses[source.identifier] = nil
            }
            self.didStartDownload(source: source)
            let operation = DownloaderOperation(request: source, memoryCache: self.memoryCache, diskCache: self.diskCache) { [weak self] (obj) in
                self?.progresses.removeValue(forKey: source.identifier)
                self?.didEndDownload(source: source)
            } progress: { [weak self] (progress) in
                self?.progresses[source.identifier] = progress
                self?.didChangeProgress(source: source)
            } failure: { [weak self] (error) in
                self?.progresses.removeValue(forKey: source.identifier)
                self?.didFailDownload(source: source)
            }
            return operation
        }
        
        //MARK: public
        
        func download(sources: [IDownloaderSource]) {
            sources.forEach { source in
                self.download(source: source, success: nil, progress: nil, failure: nil)
            }
        }
        
        func download(files: [STLibrary.File]) {
            files.forEach { file in
                if let fileOreginalUrl = file.fileOreginalUrl {
                    let source = FileDownloaderSource(file: file, fileSaveUrl: fileOreginalUrl, isThumb: false)
                    self.download(source: source, success: nil, progress: nil, failure: nil)
                }
            }
        }
        
        func add(_ listener: STFileDownloaderObserver) {
            self.observerEvents.addObject(listener)
        }
        
        func remove(_ listener: STFileDownloaderObserver) {
            self.observerEvents.removeObject(listener)
        }
        
        func hasProgress() -> Bool {
            return !self.progresses.isEmpty
        }
        
        func progress() -> Double {
            let count = self.progresses.count
            var allProgress: Double = 0
            for progresse in self.progresses {
                allProgress = allProgress + (progresse.value?.fractionCompleted ?? 0)
            }
            let result = count != .zero ? allProgress / Double(count) : .zero
            return result
        }
        
        //MARK: Private
        
        private func didStartDownload(source: IDownloaderSource) {
            self.observerEvents.forEach { observ in
                observ.downloader(didStaryDownload: self, source: source)
            }
            self.didUpdedProgress()
        }
        
        private func didEndDownload(source: IDownloaderSource) {
            self.observerEvents.forEach { observ in
                observ.downloader(didEndDownload: self, source: source)
            }
            self.didUpdedProgress()
        }
        
        private func didFailDownload(source: IDownloaderSource) {
            self.observerEvents.forEach { observ in
                observ.downloader(didFailDownload: self, source: source)
            }
            self.didUpdedProgress()
        }
        
        private func didChangeProgress(source: IDownloaderSource) {
            self.observerEvents.forEach { observ in
                observ.downloader(didChangeProgress: self, source: source)
            }
            self.didUpdedProgress()
        }
        
        private func didUpdedProgress() {
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
    
    class DownloaderDiskCache: SDownloaderManager.DiskCache<SDownloaderManager.DiskCacheObject> {
        
        override func createObject(from data: Data, source: IDownloaderSource) throws -> SDownloaderManager.DiskCacheObject {
            return SDownloaderManager.DiskCacheObject(fileName: source.fileName)
        }
        
    }
    
    struct FileDownloaderSource {
        let file: STLibrary.File
        let fileSaveUrl: URL
        let isThumb: Bool
    }
            
}

extension SDownloaderManager.FileDownloaderSource: STDownloadRequest {
   
    var fileName: String {
        return self.file.file
    }

    var parameters: [String : Any]? {
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

    var path: String {
        return "sync/downloadRedir"
    }

    var method: STNetworkDispatcher.Method {
        .post
    }

    var headers: [String : String]? {
        return nil
    }

    var encoding: STNetworkDispatcher.Encoding {
        return STNetworkDispatcher.Encoding.body
    }
    
    var fileDownloadTmpUrl: URL? {
        return self.fileTmpUrl
    }

}

extension SDownloaderManager.FileDownloaderSource: IDownloaderSource {
    
    var identifier: String {
        return "\(self.fileSaveUrl.path)_\(self.fileName)"
    }
    
    var fileTmpUrl: URL {
        return self.fileSaveUrl
    }
    
}
