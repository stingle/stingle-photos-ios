//
//  STFileRetryer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/22/21.
//

import UIKit

protocol IRetrySource: STDownloadRequest {
    var fileName: String { get }
    var version: String { get }
    var header: STHeader { get }
    var filePath: String { get }
    
    var fileTmpUrl: URL { get }
    var fileSaveUrl: URL { get }
}

extension IRetrySource {
    
    var identifier: String {
        return "\(self.version)_\(self.filePath)_\(self.fileName)"
    }
    
    var fileDownloadTmpUrl: URL? {
        return self.fileTmpUrl
    }
    
    var fileTmpUrl: URL {
        guard var url = STApplication.shared.fileSystem.tmpURL else {
            fatalError("tmpURL not found")
        }
        url.appendPathComponent(self.filePath)
        url.appendPathComponent(self.fileName)
        return url
    }
    
    var fileSaveUrl: URL {
        guard var url = STApplication.shared.fileSystem.cacheURL else {
            fatalError("cacheURL not found")
        }
        url.appendPathComponent(self.filePath)
        url.appendPathComponent(self.fileName)
        return url
    }
    
}

class STFileRetryer {
    
    private let diskCache = DiskCache()
    private let memoryCache = MemoryCache()
    private var listeners = [String: Set<Result>]()
    private let operationManager = STOperationManager.shared
    private var dispatchQueue = DispatchQueue(label: "STFileRetryer.queue")
    
    lazy var operationQueue: ATOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 10, qualityOfService: .userInitiated)
        return queue
    }()
    
    @discardableResult
    func retryImage(source: IRetrySource, success: RetryerSuccess<UIImage>?, progress: RetryerProgress?, failure: RetryerFailure?) -> String {
        let result = self.addListener(source: source, success: success, progress: progress, failure: failure)
        self.downloadImage(source: source)
        return result.listener
    }
    
    //MARK: - Private
    
    private func addListener<T>(source: IRetrySource, success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) -> Result {
        let result = Result(success: success, progress: progress, failure: failure)
        self.dispatchQueue.sync { [weak self] in
            if self?.listeners[source.identifier] != nil {
                self?.listeners[source.identifier]?.insert(result)
            } else {
                var listener = Set<Result>()
                listener.insert(result)
                self?.listeners[source.identifier] = listener
            }
        }
        return result
    }
    
    private func downloadImage(source: IRetrySource) {

        guard !self.operationQueue.allOperations().contains(where: { ($0 as? RetryOperation)?.identifier == source.identifier}) else {
            return
        }
        
        let operation = RetryOperation(request: source, memoryCache: self.memoryCache, diskCache: self.diskCache) { [weak self] (image) in
            self?.didDownloadImage(source: source, image: image)
        } progress: { [weak self] (progress) in
            self?.didProgressFile(source: source, progress: progress)
        } failure: { [weak self] (error) in
            self?.didFailureFile(source: source, error: error)
        }
        
        self.operationManager.run(operation: operation, in: self.operationQueue)
    }
    
    private func didDownloadImage(source: IRetrySource, image: UIImage) {
        self.listeners[source.identifier]?.forEach({ (result) in
            result.success(value: image)
        })
        self.dispatchQueue.sync { [weak self] in
            self?.listeners[source.identifier] = nil
        }
    }
    
    private func didProgressFile(source: IRetrySource, progress: Progress) {
        self.listeners[source.identifier]?.forEach({ (result) in
            result.progress(progress: progress)
        })
    }
    
    private func didFailureFile(source: IRetrySource, error: IError) {
        self.listeners[source.identifier]?.forEach({ (result) in
            result.failure(error: error)
        })
        self.dispatchQueue.sync { [weak self] in
            self?.listeners[source.identifier] = nil
        }
    }
    
}

private extension IRetrySource {
    
    static private var fileSystem: STFileSystem {
        return STApplication.shared.fileSystem
    }
    
    func fileDirection() throws -> URL {
        guard let path = Self.fileSystem.privateURL else {
            throw STFileRetryer.RetryerError.appInvalidData
        }
        return path.appendingPathComponent(self.fileName)
    }
    
    func removeOldVersions() throws {
        let direction = try self.fileDirection()
        let subDirectories = Self.fileSystem.subDirectories(atPath: direction.absoluteString)
    }
    
}

extension STFileRetryer {
    
    typealias RetryerSuccess<T> = (_ result: T) -> Void
    typealias RetryerProgress = (_ progress: Progress) -> Void
    typealias RetryerFailure = (_ error: IError) -> Void
    
    enum RetryerError: IError {
        case appInvalidData
        case fileNotFound
        case invalidData
        case unknown
        
        case error(error: Error)
        
        var message: String {
            switch self {
            case .appInvalidData:
                return "error_data_not_found".localized
            case .fileNotFound:
                return "error_data_not_found".localized
            case .invalidData:
                return "error_data_not_found".localized
            case .unknown:
                return "error_unknown_error".localized
            case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
                return "error_data_not_found".localized
            }
        }
    }
        
    class Result: Hashable {
                        
        fileprivate var listener: String
        private var success: RetryerSuccess<Any>?
        private var progress: RetryerProgress?
        private var failure: RetryerFailure?
        
        init<T>(success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) {
            self.listener = UUID().uuidString
            self.success = success as? STFileRetryer.RetryerSuccess<Any>
            self.failure = failure
            self.progress = progress
        }
        
        var hashValue: Int {
            return self.listener.hashValue
        }
        
        func hash(into hasher: inout Hasher) {
            return self.listener.hash(into: &hasher)
        }
        
        static func == (lhs: STFileRetryer.Result, rhs: STFileRetryer.Result) -> Bool {
            return lhs.listener == rhs.listener
        }
        
        func success(value: Any) {
            self.success?(value)
        }
        
        func progress(progress: Progress) {
            self.progress?(progress)
        }
        
        func failure(error: IError) {
            self.failure?(error)
        }
                
    }
        
}
