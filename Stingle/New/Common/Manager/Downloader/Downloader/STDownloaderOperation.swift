//
//  STRetryOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import UIKit

extension STDownloaderManager {
        
    class DownloaderOperation<T: IDiskCacheObject>: STDownloadNetworkOperation {
        
        let memoryCache: MemoryCache
        let diskCache: DiskCache<T>
                
        private(set) var results = Set<Result<T>>()
        private(set) var canEditResults = true
        private(set) var downloadProgress: Progress? = nil
        private let retrySource: IDownloaderSource
        private let retryerSuccess: RetryerSuccess<T>
        private let retryerProgress: RetryerProgress
        private let retryerFailure: RetryerFailure
        private var isRequesting = false
        
        var identifier: String {
            return (self.request as? IDownloaderSource)?.identifier ?? request.url
        }
        
        var progressValue: Float {
            guard let downloadProgress = self.downloadProgress else {
                return 0
            }
            let total: Float = downloadProgress.totalUnitCount == 0 ? 1 : Float(downloadProgress.totalUnitCount)
            let completed = Float(downloadProgress.completedUnitCount)
            let progress = completed / total
            return progress
        }

        init(request: IDownloaderSource, memoryCache: MemoryCache, diskCache: DiskCache<T>, success: @escaping RetryerSuccess<T>, progress: @escaping RetryerProgress, failure: @escaping RetryerFailure) {
            
            self.retryerSuccess = success
            self.retryerProgress = progress
            self.retryerFailure = failure
           
            self.retrySource = request
            self.memoryCache = memoryCache
            self.diskCache = diskCache
            super.init(request: request, success: nil, progress: nil, failure: nil)
        }
        
        //MARK: - override
        
        override func startRequest() {
            guard !self.isRequesting else {
                return
            }
            self.isRequesting = true
            self.startOperation(sendRequest: true)
        }
        
        override func responseSucces(result: Any) {
            self.isRequesting = false
            self.canEditResults = false
            DispatchQueue.global().async { [weak self] in
                self?.responseEndSucces(result: result)
            }
        }
                
        override func responseFailed(error: IError) {
            self.results.forEach { (result) in
                if result.isResponsive {
                    result.failure(error: error)
                }
            }
            self.isRequesting = false
            self.canEditResults = false
            super.responseFailed(error: error)
            self.retryerFailure(error)
        }
        
        override func responseProgress(result: Progress) {
            self.results.forEach { (resultProgress) in
                if resultProgress.isResponsive {
                    resultProgress.progress(progress: result)
                }
            }
            self.downloadProgress = result
            super.responseProgress(result: result)
            self.retryerProgress(result)
        }
        
        //MARK: - public
        
        func localWork() {
            self.startOperation(sendRequest: false)
        }
        
        @discardableResult
        func insert(result: Result<T>) -> Bool {
            let canInset = self.canEditResults && !self.isExpired
            if canInset {
                self.results.insert(result)
            }
            return canInset
        }
        
        @discardableResult
        func remove(result: Result<T>) -> Bool {
            let canRemove = self.canEditResults && !self.isExpired
            if canRemove {
                self.results.remove(result)
            }
            result.isResponsive = false
            return canRemove
        }
                
        //MARK: - private
        
        private func responseEndSucces(result: Any) {
            do {
                try self.memoryCache.didDownload(source: self.retrySource)
                try self.diskCache.didAddedMemry(source: self.retrySource)
                self.diskCache.retryFile(source: self.retrySource) { [weak self] (result) in
                    self?.responseSucces(obj: result)
                } failure: { [weak self] (error) in
                    self?.responseFailed(error: error)
                }
                
            } catch {
                let error = RetryerError.error(error: error)
                self.responseFailed(error: error)
            }
            do {
                self.memoryCache.resetCache(source: self.retrySource)
            }
        }
        
        private func responseSucces(obj: T) {
            self.results.forEach { (result) in
                if result.isResponsive {
                    result.success(value: obj)
                }
            }
            super.responseSucces(result: self.retrySource.fileTmpUrl)
            self.retryerSuccess(obj)
        }
        
        private func startOperation(sendRequest: Bool) {
            self.diskCache.retryFile(source: self.retrySource) { [weak self] (image) in
                self?.responseSucces(obj: image)
            } failure: { [weak self] (error) in
                if !sendRequest {
                    return
                }
                if let error = error as? RetryerError {
                    switch error {
                    case .fileNotFound:
                        self?.diskCacheDataNotFound()
                    default:
                        self?.responseFailed(error: error)
                    }
                } else {
                    self?.responseFailed(error: error)
                }
            }
        }
        
        private func diskCacheDataNotFound() {
            self.memoryCache.retryFile(source: self.retrySource) { [weak self] (_) in
                if let weakSelf = self {
                    do {
                        try weakSelf.diskCache.didAddedMemry(source: weakSelf.retrySource)
                        guard let object = weakSelf.diskCache.object(for: weakSelf.retrySource.identifier) else {
                            weakSelf.responseFailed(error: RetryerError.unknown)
                            return
                        }
                        weakSelf.responseSucces(obj: object)
                    } catch {
                        weakSelf.responseFailed(error: RetryerError.error(error: error))
                    }
                }
            } failure: { [weak self] (error) in
                if let error = error as? RetryerError {
                    switch error {
                    case .fileNotFound:
                        self?.memoryCacheDataNotFound()
                    default:
                        self?.responseFailed(error: error)
                    }
                } else {
                    self?.responseFailed(error: error)
                }
            }
        }
        
        private func memoryCacheDataNotFound() {
            super.startRequest()
        }
              
    }
    
}
