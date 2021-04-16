//
//  STNetworkDispatcher.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation
import Alamofire

protocol NetworkTask {
	
	func cancel()
	func suspend()
	func resume()
	var taskState: STNetworkDispatcher.TaskState { get }
	
}

extension URLSessionDataTask: NetworkTask {
	var taskState: STNetworkDispatcher.TaskState {
		return STNetworkDispatcher.TaskState(rawValue: self.state.rawValue) ?? .running
	}
}

typealias IDecoder = DataDecoder

class STNetworkDispatcher {
    
    static let sheared: STNetworkDispatcher = STNetworkDispatcher()

    private lazy var session: Alamofire.Session = {
        return AF
    }()
    
    private lazy var backgroundSession: Alamofire.Session = {
        #if targetEnvironment(simulator)
        return self.session
        #else
        let backgroundSessionManager = Alamofire.Session(configuration: URLSessionConfiguration.background(withIdentifier: "Alamofire.backgroundSessio"))
        return backgroundSessionManager
        #endif
    }()
		
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
	
	private init() {}
     
		
	@discardableResult
	func request<T: Decodable>(request: IRequest, decoder: IDecoder? = nil, completion: @escaping (Result<T>) -> Swift.Void) -> NetworkTask? {
        let decoder = decoder ?? self.decoder
		let request = request.asDataRequest
		request.responseDecodable(decoder: decoder) { (response: AFDataResponse<T>) in
			switch response.result {
			case .success(let value):
				completion(.success(result: value))
			case .failure(let networkError):
				let error = NetworkError.error(error: networkError)
				completion(.failure(error: error))
			}
		}
		return Task(request: request)
	}
    
    @discardableResult
    func requestJSON(request: IRequest, completion: @escaping (Result<Any>) -> Swift.Void) -> NetworkTask? {
        let request = request.asDataRequest
        request.responseJSON(completionHandler: { (response: AFDataResponse<Any>) in
            switch response.result {
            case .success(let value):
                completion(.success(result: value))
            case .failure(let networkError):
                let error = NetworkError.error(error: networkError)
                completion(.failure(error: error))
            }
        })
        return Task(request: request)
    }
    
    @discardableResult
    func requestData(request: IRequest, completion: @escaping (Result<Data>) -> Swift.Void) -> NetworkTask? {
        let request = request.asDataRequest
        request.responseData { (response) in
            switch response.result {
            case .success(let value):
                completion(.success(result: value))
            case .failure(let networkError):
                let error = NetworkError.error(error: networkError)
                completion(.failure(error: error))
            }
        }
        return Task(request: request)
    }
    
    func download(request: IDownloadRequest, completion: @escaping (Result<URL>) -> Swift.Void, progress: @escaping (Progress) -> Swift.Void) -> NetworkTask? {
        guard let fileUrl = request.fileDownloadTmpUrl else {
            completion(.failure(error: NetworkError.badRequest))
            return nil
        }
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
                
        let downloadRequest = AF.download(request.url, method: request.AFMethod, parameters: request.parameters, headers: request.afHeaders, to: destination).response { response in
            if let error = response.error {
                let networkError = NetworkError.error(error: error)
                completion(.failure(error: networkError))
            } else if let fileUrl = response.fileURL {
                completion(.success(result: fileUrl))
            } else {
                completion(.failure(error: NetworkError.dataNotFound))
            }
        }.downloadProgress { (process) in
            progress(process)
        }
        return Task(request: downloadRequest)
    }
    
    func upload<T: Decodable>(request: IUploadRequest, progress: ProgressTask?, completion: @escaping (Result<T>) -> Swift.Void)  -> NetworkTask? {
        
        let uploadRequest = self.session.upload(multipartFormData: { (data) in
            request.files.forEach { (file) in
                data.append(file.fileUrl, withName: file.name, fileName: file.fileName, mimeType: file.type)
            }
            if let parameters = request.parameters {
                for parame in parameters {
                    if  let vData = "\(parame.value)".data(using: .utf8) {
                        data.append(vData, withName: parame.key)
                    }
                }
            }
        },  to: request.url, method: request.AFMethod, headers: request.afHeaders).responseDecodable(completionHandler: { (response: AFDataResponse<T>) in
            switch response.result {
            case .success(let value):
                completion(.success(result: value))
            case .failure(let networkError):
                let error = NetworkError.error(error: networkError)
                completion(.failure(error: error))
            }
        } ).uploadProgress { (uploadProgress) in
            progress?(uploadProgress)
        }

        return Task(request: uploadRequest)
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
	
	fileprivate struct Task: NetworkTask {
		
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

protocol IRequestEncoding: ParameterEncoding {
	func encodeParameters(_ urlRequest: URLRequest, with parameters: [String : Any]?) throws -> URLRequest
}

extension IRequestEncoding {
	
	func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
		return try self.encodeParameters(urlRequest.asURLRequest(), with: parameters)
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
