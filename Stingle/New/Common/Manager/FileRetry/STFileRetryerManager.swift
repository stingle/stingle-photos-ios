//
//  STFileRetryerManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import Foundation

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
        return self.fileSaveUrl
    }
    
    var fileSaveUrl: URL {
        guard let url = STApplication.shared.fileSystem.cacheURL else {
            fatalError("cacheURL not found")
        }
        var result = url.appendingPathComponent(self.filePath)
        result = result.appendingPathComponent(self.fileName)
        return result
    }
    
}

class STFileRetryerManager {
    
    let imageRetryer = ImageRetryer()
    
}

extension STFileRetryerManager {
    
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
        
    class Result<T>: Hashable {
                        
        let identifier: String
        private var success: RetryerSuccess<T>?
        private var progress: RetryerProgress?
        private var failure: RetryerFailure?
        
        init(success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?) {
            self.identifier = UUID().uuidString
            self.success = success
            self.failure = failure
            self.progress = progress
            
        }
        
        init(success: RetryerSuccess<T>?, progress: RetryerProgress?, failure: RetryerFailure?, identifier: String) {
            self.identifier = identifier
            self.success = success
            self.failure = failure
            self.progress = progress
        }
        
        var hashValue: Int {
            return self.identifier.hashValue
        }
        
        func hash(into hasher: inout Hasher) {
            return self.identifier.hash(into: &hasher)
        }
        
        static func == (lhs: Result<T>, rhs: Result<T>) -> Bool {
            return lhs.identifier == rhs.identifier
        }
        
        func success(value: T) {
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

