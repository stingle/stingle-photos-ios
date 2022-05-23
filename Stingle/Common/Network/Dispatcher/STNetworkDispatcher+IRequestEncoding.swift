//
//  STNetworkDispatcher+IRequestEncoding.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/9/21.
//

import Alamofire
import Foundation

protocol IRequestEncoding: ParameterEncoding {
    func encodeParameters(_ urlRequest: URLRequest, with parameters: [String : Any]?) throws -> URLRequest
}

extension IRequestEncoding {
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        return try self.encodeParameters(urlRequest.asURLRequest(), with: parameters)
    }
    
}

extension STNetworkDispatcher {
    
    enum Result<T> {
        case success(result: T)
        case failure(error: NetworkError)
    }
    
    typealias ProgressTask = (_ progress: Progress) -> Void
    
    enum NetworkError: IError {
        
        case badRequest
        case dataNotFound
        case cancelled
        case error(error: Error)
        
        var message: String {
            switch self {
            case .badRequest:
                return "nework_error_bad_request".localized
            case .dataNotFound:
                return "nework_error_data_not_found".localized
            case .cancelled:
                return "nework_error_request_cancelled".localized
            case .error(let error):
                if let error = error as? IError {
                    return error.localizedDescription
                }
                return error.localizedDescription
            }
        }
        
        var isCancelled: Bool {
            switch self {
            case .cancelled:
                return true
            case .error(let error):
                if let asAFError = error.asAFError {
                    return asAFError.isCancelled || asAFError.isExplicitlyCancelledError
                }
                return false
            default:
                return false
            }
        }
    }
    
    enum Encoding {
        case queryString
        case body
        case coustom(encoer: IRequestEncoding)
    }
    
}

extension STNetworkDispatcher.Encoding: IRequestEncoding {

    func encodeParameters(_ urlRequest: URLRequest, with parameters: [String : Any]?) throws -> URLRequest {
        switch self {
        case .queryString:
            return try URLEncoding.queryString.encode(urlRequest, with: parameters)
        case .body:
            return try URLEncoding.default.encode(urlRequest, with: parameters)
        case .coustom(let encoer):
            return try encoer.encodeParameters(urlRequest, with: parameters)
        }
    }

}

extension STNetworkDispatcher {
    
    enum Method: String {
        case get     = "GET"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
    }
    
    enum TaskState: Int {
        case running = 0
        case suspended = 1
        case canceling = 2
        case completed = 3
    }
    
    struct Task: INetworkTask {
        
        let request: Request
        
        func cancel() {
            self.request.cancel()
        }
        
        func suspend() {
            self.request.suspend()
        }
        
        func resume() {
            self.request.resume()
        }
        
        var taskState: STNetworkDispatcher.TaskState {
            switch self.request.state {
            case .initialized, .resumed:
                return .running
            case .suspended:
                return .suspended
            case .cancelled:
                return .canceling
            case .finished:
                return .completed
            }
        }
    }
    
    struct SessionTask: INetworkTask {
        
        let sessionTask: URLSessionTask
        
        func cancel() {
            self.sessionTask.cancel()
        }
        
        func suspend() {
            self.sessionTask.suspend()
        }
        
        func resume() {
            self.sessionTask.resume()
        }
        
        var taskState: STNetworkDispatcher.TaskState {
            switch self.sessionTask.state {
            case .running:
                return .running
            case .suspended:
                return .suspended
            case .canceling:
                return .canceling
            case .completed:
                return .completed
            @unknown default:
                return .suspended
            }
        }
    }
    
}

extension AFError: IError {
    
    var message: String {
        switch self {
        default:
            return "nework_error_bad_request".localized
        }
    }

}
