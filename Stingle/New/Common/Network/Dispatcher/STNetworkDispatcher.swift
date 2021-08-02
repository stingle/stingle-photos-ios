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

typealias IDecoder = DataDecoder

class STNetworkDispatcher {
    
    static let sheared: STNetworkDispatcher = STNetworkDispatcher()

    private lazy var session: Alamofire.Session = {
        let config = URLSessionConfiguration.default
        let session = Alamofire.Session(configuration: config, eventMonitors: [self])
        return session
    }()
    
    private lazy var uploadSession: Alamofire.Session = {
        let config = URLSessionConfiguration.default
        let session = Alamofire.Session(configuration: config, eventMonitors: [self])
        return session
    }()
    
    private lazy var streanSession: Alamofire.Session = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = Alamofire.Session(configuration: config, eventMonitors: [self])
        return session
    }()
        
    private lazy var backgroundSession: Alamofire.Session = {
        #if targetEnvironment(simulator)
        return self.session
        #else
        let backgroundSessionManager = Alamofire.Session(configuration: URLSessionConfiguration.background(withIdentifier: "Alamofire.backgroundSessio"))
        return backgroundSessionManager
        #endif
    }()
    
    private lazy var downloadSession: Alamofire.Session = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = Alamofire.Session(configuration: config, eventMonitors: [self])
        return session
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
        let request = self.afRequest(request: request, sesion: self.session)
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
        let request = self.afRequest(request: request, sesion: self.session)
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
        let request = self.afRequest(request: request, sesion: self.session)
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
        
        let downloadRequest = self.downloadSession.download(request.url, method: request.AFMethod, parameters: request.parameters, headers: request.afHeaders, to: destination).response { response in
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
        
        let uploadRequest = self.uploadSession.upload(multipartFormData: { (data) in
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
    
    func stream(request: IStreamRequest, queue: DispatchQueue, stream: @escaping (_ chank: Data) -> Swift.Void, completion: @escaping (Result<(requestLength: UInt64, contentLength: UInt64, range: Range<UInt64>)>) -> Swift.Void) -> NetworkTask? {
        
        let dataRequest = self.afRequest(request: request, sesion: self.streanSession)
        
        let urlRequest = try! dataRequest.convertible.asURLRequest()
        let streamRequest = self.streanSession.streamRequest(urlRequest).responseStream(on: queue) { response in
            
            var errorIsResponseed = false
            
            if let error = response.error {
                let networkError = NetworkError.error(error: error)
                completion(.failure(error: networkError))
                errorIsResponseed = true
            } else if let value = response.value {
                stream(value)
            }
            
            if let responseCompletion = response.completion {
                
                if let error = responseCompletion.error {
                    if !errorIsResponseed {
                        let networkError = NetworkError.error(error: error)
                        completion(.failure(error: networkError))
                    }
                } else if let allHeaderFields = responseCompletion.response?.allHeaderFields {
                    let contentLengthStrFull = allHeaderFields["Content-Length"] as? String ?? ""
                    let requestLength = UInt64(contentLengthStrFull) ?? .zero
                    
                    var contentRangeStr = allHeaderFields["Content-Range"] as? String
                    contentRangeStr = contentRangeStr?.components(separatedBy: " ").last
                    
                    let components = contentRangeStr?.components(separatedBy: "/")
                    
                    let requestRangeStr = components?.first
                    let contentLengthStr = components?.last ?? ""
                    
                    var lower: UInt64 = .zero
                    var upper: UInt64 = .zero
                    
                    if let ranges = requestRangeStr?.components(separatedBy: "-"), ranges.count == 2 {
                        lower = UInt64(ranges[0]) ?? .zero
                        upper = UInt64(ranges[1]) ?? .zero
                    }
                    
                    let contentLength = UInt64(contentLengthStr) ?? .zero
                    let range = Range(uncheckedBounds: (lower, upper))
                    let result = (requestLength: requestLength, contentLength: contentLength, range: range)
                    completion(.success(result: result))
                    
                } else {
                    if !errorIsResponseed {
                        let networkError = NetworkError.badRequest
                        completion(.failure(error: networkError))
                    }
                }
            }
        }
        
        return Task(request: streamRequest)
    }
    
    
        		
}


extension STNetworkDispatcher: EventMonitor {
    
    func afRequest(request: IRequest, sesion: Alamofire.Session) -> DataRequest {
        let url = request.url
        guard let components = URLComponents(string: url) else {
            fatalError()
        }
        return sesion.request(components, method: request.AFMethod, parameters: request.parameters, encoding: request.encoding, headers: request.afHeaders, interceptor: nil).validate(statusCode: 200..<300)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let response = STResponse<STLogoutResponse>(from: data) else {
            return
        }
        STApplication.shared.networkDispatcher(didReceive: self, logOunt: response)
    }
    
}
