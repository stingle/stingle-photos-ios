//
//  STWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/18/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

open class STWorker {
	
    public typealias Result<T> = STNetworkDispatcher.Result<T>
    public typealias Success<T> = (_ result: T) -> Void
    public typealias ProgressTask = (_ progress: Progress) -> Void
    public typealias StreamTask = (_ progress: Data) -> Void
    public typealias Failure = (_ error: IError) -> Void
	
	let operationManager = STOperationManager.shared
    
    public init() {}
			
	//MARK: New request
	
	func request<T: IResponse>(request: IRequest, success: Success<T>? = nil, failure: Failure? = nil) {
        let operation = STNetworkOperationDecodable<T>(request: request, success: { (result) in
            success?(result)
        }) { (error) in
            failure?(error)
        }
        self.operationManager.run(operation: operation)
	}
	
	func request<T: Decodable>(request: IRequest, success: Success<T>?, failure: Failure? = nil) {
		self.request(request: request, success: { (response: STResponse<T>) in
			guard response.errors.isEmpty else {
				failure?(WorkerError.errors(errors: response.errors))
				return
			}
			guard response.status == "ok" else {
				failure?(WorkerError.status(status: response.status))
				return
			}
			guard let parts = response.parts else {
				failure?(WorkerError.emptyData)
				return
			}
			success?(parts)
		}, failure: failure)
	}
    
    func requestData(request: IRequest, success: Success<Data>?, failure: Failure? = nil) {
        let operation = STDataNetworkOperation(request: request) { (data) in
            success?(data)
        } failure: { (error) in
            failure?(error)
        }
        self.operationManager.run(operation: operation)
    }
    
}

//MARK: - Upload

extension STWorker {
    
    @discardableResult
    func upload<T: IResponse>(request: IUploadRequest, success: Success<T>?, progress: ProgressTask? = nil, failure: Failure? = nil) -> STUploadNetworkOperation<T> {
        let operation = STUploadNetworkOperation<T>(request: request, success: { (result) in
            success?(result)
        }, failure: failure, progress: progress)
        self.operationManager.runUpload(operation: operation)
        return operation
    }
    
    @discardableResult
    func upload<T: Decodable>(request: IUploadRequest, success: Success<T>?, progress: ProgressTask? = nil, failure: Failure? = nil) -> STUploadNetworkOperation<STResponse<T>> {
        
        let operation = self.upload(request: request, success: { (response: STResponse<T>) in
            guard response.errors.isEmpty else {
                failure?(WorkerError.errors(errors: response.errors))
                return
            }
            guard response.status == "ok" else {
                failure?(WorkerError.status(status: response.status))
                return
            }
            guard let parts = response.parts else {
                failure?(WorkerError.emptyData)
                return
            }
            success?(parts)
        }, progress: progress, failure: failure)
        
        return operation
    }
    
    @discardableResult
    func download(request: IDownloadRequest, success: Success<URL>?, progress: ProgressTask? = nil, failure: Failure? = nil) -> STDownloadNetworkOperation {
        let operation = STDownloadNetworkOperation(request: request, success: { url in
            success?(url)
        }, progress: { myProgress in
            progress?(myProgress)
        }, failure: failure)        
        self.operationManager.runDownload(operation: operation)
        return operation
    }
    
    @discardableResult
    func stream(request: IStreamRequest, queue: DispatchQueue, success: Success<(requestLength: UInt64, contentLength: UInt64, range: Range<UInt64>)>?, stream: @escaping StreamTask, failure: Failure? = nil) -> STStreamNetworkOperation {
                
        let operation = STStreamNetworkOperation(request: request, queue: queue) { result in
            success?(result)
        } stream: { data in
            stream(data)
        } failure: { error in
            failure?(error)
        }
        self.operationManager.runStream(operation: operation)
        return operation
     
    }
        
}

extension STWorker {
	
	enum WorkerError: IError {
		
		case emptyData
        case unknown
		case error(error: Error)
		case errors(errors: [String])
		case status(status: String)
		
		var message: String {
			switch self {
			case .emptyData:
				return "empty_data".localized
            case .unknown:
                return "error_unknown_error".localized
			case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
				return error.localizedDescription
			case .errors(let errors):
				return errors.joined(separator: "\n")
			case .status(let status):
				return status
			}
		}
	}

}
