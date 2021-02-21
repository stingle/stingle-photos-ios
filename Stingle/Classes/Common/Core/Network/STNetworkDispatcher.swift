//
//  STNetworkDispatcher.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

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

protocol IDecoder {
	func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

extension JSONDecoder: IDecoder {}

class STNetworkDispatcher {
		
	static let sheared: STNetworkDispatcher = STNetworkDispatcher()
	private init() {}
	
	private let session = URLSession.shared
	
	@discardableResult
	func request<T: IResponse>(request: IRequest, completion: @escaping (Result<T>) -> Swift.Void) -> NetworkTask? {
		do {
			let urlRequest = try self.create(request: request)
			let task = self.resume(request: urlRequest) { (resultData) in
				switch resultData{
				case .success(let result):
					let decoder = JSONDecoder()
					decoder.keyDecodingStrategy = .convertFromSnakeCase
					do {
						let response: T = try decoder.decode(T.self, from: result)
						completion(.success(result: response))
					} catch {
						completion(.failure(error: .error(error: error)))
					}
					break
				case .failure(let error):
					completion(.failure(error: error))
				}
			}
			task.resume()
			return task
		} catch {
			completion(.failure(error: NetworkError.error(error: error)))
			return nil
		}
	}
	
	//MARK: - Private func
	
	private func resume(request: URLRequest, completion: @escaping (Result<Data>) -> Swift.Void) -> NetworkTask {
		let task = self.session.dataTask(with: request) { (data, response, error) in
			guard let data = data, error == nil else {
				if let error = error {
					completion(.failure(error: .error(error: error)))
					return
				}
				completion(.failure(error: .dataNotFound))
				return
			}
			completion(.success(result: data))
		}
		
		return task
	}
	
	private func create(request: IRequest) throws -> URLRequest {
		let url = URL(string: request.url)
		guard let requestUrl = url else {
			throw NetworkError.badRequest
		}
		var urlRequest = URLRequest(url: requestUrl)
		urlRequest.httpMethod = request.method.rawValue
		if let headers = request.headers {
			for key in headers.keys {
				if let value = headers[key] {
					urlRequest.setValue(value, forHTTPHeaderField: key)
				}
			}
		}
		urlRequest = try request.encoding.encode(urlRequest, with: request.parameters)
		return urlRequest
	}
	
}

extension STNetworkDispatcher {
	
	enum TaskState: Int {
		case running = 0
		case suspended = 1
		case canceling = 2
		case completed = 3
	}
	
	enum Encoding {
		case queryString
		case body
	}
		
}

extension STNetworkDispatcher.Encoding: RequestEncoding {

	func encode(_ urlRequest: URLRequest, with parameters: [String : String?]?) throws -> URLRequest {
		var urlRequest = urlRequest
		switch self {
		case .queryString:
			guard let url = urlRequest.url?.absoluteString else {
				throw STNetworkDispatcher.NetworkError.badRequest
			}
			var components = URLComponents(string: url)
			components?.queryItems = parameters?.compactMap({ (arg0) -> URLQueryItem in
				return URLQueryItem(name: arg0.key, value: arg0.value)
			})
			urlRequest.url = components?.url
			return urlRequest
		case .body:
			var components = URLComponents()
			components.queryItems = parameters?.compactMap({ (arg0) -> URLQueryItem in
				return URLQueryItem(name: arg0.key, value: arg0.value)
			})
			let strParams = components.url?.absoluteString
			let bodyStr = String((strParams?.dropFirst())!)
			urlRequest.httpBody = bodyStr.data(using: .utf8)
			return urlRequest
		}
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
	
}
