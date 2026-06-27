//
//  STFileRetryerManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import Foundation

public class STDownloaderManager {

    public let imageRetryer = ImageRetryer()
    public let fileDownloader = FileDownloader()
    // Auto-caching of played videos goes through its own downloader so it can't pile
    // up: watching many videos quickly enqueues many full-file downloads, and on the
    // shared `fileDownloader` (20-wide) they'd all run at once and starve the
    // foreground stream. This one runs a single download at a time; the rest queue.
    public let videoCacheDownloader = VideoCacheDownloader()

}

public extension STDownloaderManager {
    
    typealias RetryerSuccess<T> = (_ result: T) -> Void
    typealias RetryerProgress = (_ progress: Progress) -> Void
    typealias RetryerFailure = (_ error: IError) -> Void
    
    enum RetryerError: IError {
        case appInvalidData
        case fileNotFound
        case invalidData
        case unknown
        
        case error(error: Error)
        
        public var message: String {
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
        
        public var hashValue: Int {
            return self.identifier.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            return self.identifier.hash(into: &hasher)
        }
        
        public static func == (lhs: Result<T>, rhs: Result<T>) -> Bool {
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

