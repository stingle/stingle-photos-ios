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
	
	private init() {}
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
		
	@discardableResult
	func request<T: Decodable>(request: IRequest, decoder: IDecoder? = nil, completion: @escaping (Result<T>) -> Swift.Void) -> NetworkTask? {
        let decoder = decoder ?? self.decoder
		let request = self.create(request: request)
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
        let request = self.create(request: request)
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
        let request = self.create(request: request)
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
	
	//MARK: - Private func
	
	private func create(request: IRequest) -> DataRequest {
		let url = request.url
		guard let components = URLComponents(string: url) else {
			fatalError()
		}
		return AF.request(components, method: request.method.AFMethod, parameters: request.parameters, encoding: request.encoding, headers: request.afHeaders, interceptor: nil).validate(statusCode: 200..<300)
	}
	
}

extension STNetworkDispatcher {
	
	enum Result<T> {
		case success(result: T)
		case failure(error: NetworkError)
	}
	
	enum NetworkError: IError {
		
		case badRequest
		case dataNotFound
		case error(error: Error)
		
		var message: String {
			switch self {
			case .badRequest:
				return "nework_error_bad_request".localized
			case .dataNotFound:
				return "nework_error_data_not_found".localized
			case .error(let error):
				if let error = error as? IError {
					return error.localizedDescription
				}
				return error.localizedDescription
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

private extension STNetworkDispatcher.Method {
	
	var AFMethod: Alamofire.HTTPMethod {
		switch self {
		case .get:
			return .get
		case .post:
			return .post
		case .put:
			return .put
		case .patch:
			return .patch
		case .delete:
			return .delete
		}
	}
	
}

extension IRequest {
	
	var afHeaders: Alamofire.HTTPHeaders? {
		if let header = self.headers {
			return Alamofire.HTTPHeaders(header)
		}
		return nil
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
