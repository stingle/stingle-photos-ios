//
//  STSignUpWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/18/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

class STAuthWorker: STWorker {
	
	private let crypto = Crypto()
	
	func register(email: String, password: String, includePrivateKey: Bool, success: Success<STAuth.Register>? = nil, failure: Failure? = nil) {
		do {
			let request = try self.generateSignUpRequest(email: email, password: password, includePrivateKey: includePrivateKey)
			self.request(request: request, success: success, failure: failure)
		} catch {
			failure?(WorkerError.error(error: error))
		}
	}
	
	func login(email: String, password: String, includePrivateKey: Bool, success: Success<STAuth.Login>? = nil, failure: Failure? = nil) {
		
	}
	
	//MARK: - Private
	
	private func generateSignUpRequest(email: String, password: String, includePrivateKey: Bool) throws -> STAuthRequest {
		do {
			try self.crypto.generateMainKeypair(password: password)
			guard let pwdHash = try self.crypto.getPasswordHashForStorage(password: password), let salt = pwdHash["salt"], let pwd = pwdHash["hash"], let keyBundle = try KeyManagement.getUploadKeyBundle(password: password, includePrivateKey: includePrivateKey)  else {
				throw AuthWorkerError.passwordError
			}
			return STAuthRequest.register(email: email, password: pwd, salt: salt, keyBundle: keyBundle, isBackup: includePrivateKey)
		} catch {
			throw WorkerError.error(error: error)
		}
	}
	
}

extension STAuthWorker {
	
	enum AuthWorkerError: IError {
		case passwordError
		
		var message: String {
			switch self {
			case .passwordError:
				return "incorrect_password".localized
			}
		}
		
	}
	
}
