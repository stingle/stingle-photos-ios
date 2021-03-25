//
//  STRetryOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import UIKit

extension STFileRetryerManager {
        
    class RetryOperation<T: IDiskCacheObject>: STDownloadNetworkOperation {
        
        let memoryCache: MemoryCache
        let diskCache: DiskCache<T>
        private let retrySource: IRetrySource
        
        private let retryerSuccess: RetryerSuccess<T>
        private let retryerProgress: RetryerProgress
        private let retryerFailure: RetryerFailure
        private(set) var downloadProgress: Progress? = nil
        
        private var isRequesting = false
        
        var identifier: String {
            return (self.request as? IRetrySource)?.identifier ?? request.url
        }

        init(request: IRetrySource, memoryCache: MemoryCache, diskCache: DiskCache<T>, success: @escaping RetryerSuccess<T>, progress: @escaping RetryerProgress, failure: @escaping RetryerFailure) {
            
            self.retryerSuccess = success
            self.retryerProgress = progress
            self.retryerFailure = failure
           
            self.retrySource = request
            self.memoryCache = memoryCache
            self.diskCache = diskCache
            super.init(request: request, success: nil, progress: nil, failure: nil)
            self.startOperation(sendRequest: false)
        }
        
        override func startRequest() {
            guard !self.isRequesting else {
                return
            }
            self.isRequesting = true
            self.startOperation(sendRequest: true)
        }
        
        override func responseSucces(result: Any) {
            self.isRequesting = false
            DispatchQueue.global().async { [weak self] in
                self?.responseEndSucces(result: result)
            }
        }
                
        override func responseFailed(error: IError) {
            self.isRequesting = false
            super.responseFailed(error: error)
            self.retryerFailure(error)
        }
        
        override func responseProgress(result: Progress) {
            self.downloadProgress = result
            super.responseProgress(result: result)
            self.retryerProgress(result)
        }
        
        //MARK: - private
        
        private func responseEndSucces(result: Any) {
            do {
                try self.memoryCache.didDownload(source: self.retrySource)
                try self.diskCache.didAddedMemry(source: self.retrySource)
                
                guard let image = self.diskCache.object(for: self.retrySource.identifier) else {
                    self.responseFailed(error: RetryerError.unknown)
                    return
                }
                self.retryerSuccess(image)
                super.responseSucces(result: result)
            } catch {
                let error = RetryerError.error(error: error)
                self.responseFailed(error: error)
            }
        }
        
        private func responseSucces(image: T) {
            super.responseSucces(result: self.retrySource.fileTmpUrl)
            self.retryerSuccess(image)
        }
        
        private func startOperation(sendRequest: Bool) {
            self.diskCache.retryFile(source: self.retrySource) { [weak self] (image) in
                self?.responseSucces(image: image)
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
            self.memoryCache.retryFile(source: self.retrySource) { [weak self] (data) in
                if let weakSelf = self {
                    do {
                        try weakSelf.diskCache.didAddedMemry(source: weakSelf.retrySource)
                        guard let image = weakSelf.diskCache.object(for: weakSelf.retrySource.identifier) else {
                            weakSelf.responseFailed(error: RetryerError.unknown)
                            return
                        }
                        weakSelf.responseSucces(image: image)
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
