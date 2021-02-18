//
//  STWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/18/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

class STWorker {
	
	typealias Success<T> = (_ result: T) -> Void
	typealias Failure = (_ error: WorkerError) -> Void
	
	let networkManager = NetworkManager.self
	
	func request<T: IResponse>(request: SPRequest, success: Success<T>? = nil, failure: Failure? = nil) {
		self.networkManager.send(request: request) { (response: T?, error) in
			if let response = response {
				DispatchQueue.main.async {
					success?(response)
				}
			} else if let error = error {
				DispatchQueue.main.async {
					failure?(WorkerError.error(error: error))
				}
			} else {
				DispatchQueue.main.async {
					failure?(WorkerError.emptyData)
				}
			}
		}
	}
	
	func request<T: Codable>(request: SPRequest, success: Success<T>?, failure: Failure? = nil) {
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
	
}

extension STWorker {
	
	enum WorkerError: IError {
		
		case emptyData
		case error(error: Error)
		case errors(errors: [String])
		case status(status: String)
		
		var message: String {
			switch self {
			case .emptyData:
				return "empty_data".localized
			case .error(let error):
				return error.localizedDescription
			case .errors(let errors):
				return errors.joined(separator: "\n")
			case .status(let status):
				return status
			}
		}
	}

}
