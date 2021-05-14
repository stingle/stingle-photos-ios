//
//  STFileRetryerManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import Foundation

class SDownloaderManager {
    
    let imageRetryer = ImageRetryer()
    let fileDownloader = FileDownloader()
    
}

extension SDownloaderManager {
    
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
        var isResponsive = true
        
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

