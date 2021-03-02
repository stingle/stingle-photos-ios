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
	
	private lazy var db: DataBase = {
		do {
			return try DataBase.shared()
		} catch {
			print(error)
			fatalError()
		}
	}()
	
	func register(email: String, password: String, includePrivateKey: Bool, success: Success<STAuth.Register>? = nil, failure: Failure? = nil) {
		do {
			let request = try self.generateSignUpRequest(email: email, password: password, includePrivateKey: includePrivateKey)
			self.request(request: request, success: success, failure: failure)
		} catch {
			failure?(WorkerError.error(error: error))
		}
	}
		
	func login(email: String, password: String, success: Success<User>? = nil, failure: Failure? = nil) {
		self.preLogin(email: email, success: { [weak self] (preLogin) in
			guard let weakSelf = self else {
				failure?(AuthWorkerError.loginError)
				return
			}
			do {
				let pHash = try weakSelf.crypto.getPasswordHashForStorage(password: password, salt: preLogin.salt)
				weakSelf.finishLogin(email: email, password: password, pHash: pHash, success: success, failure: failure)
			} catch {
				failure?(WorkerError.error(error: error))
			}
		}, failure: failure)
	}
	
	func registerAndLogin(email: String, password: String, includePrivateKey: Bool, success: Success<User>? = nil, failure: Failure? = nil) {
		self.register(email: email, password: password, includePrivateKey: includePrivateKey, success: { [weak self] (register) in
			guard let weakSelf = self else {
				failure?(AuthWorkerError.loginError)
				return
			}
			weakSelf.login(email: email, password: password, success: success, failure: failure)
		}, failure: failure)
	}
	
	//MARK: - Private Register
	
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
	
	//MARK: - Private Login
	
	private func preLogin(email: String, success: Success<STAuth.PreLogin>? = nil, failure: Failure? = nil) {
		let request = STAuthRequest.preLogin(email: email)
		self.request(request: request, success: success, failure: failure)
	}
	
	private func finishLogin(email: String, password: String, pHash: String, success: Success<User>? = nil, failure: Failure? = nil) {
		let request = STAuthRequest.login(email: email, password: pHash)
		self.request(request: request, success: { [weak self] (response: STAuth.Login) in
			guard let weakSelf = self else {
				failure?(AuthWorkerError.loginError)
				return
			}
			do {
				let user = try weakSelf.updateUserParams(login: response, email: email, password: password)
				success?(user)
			} catch {
				failure?(AuthWorkerError.loginError)
			}
			
		}, failure: failure)
	}
	
	private func updateUserParams(login: STAuth.Login, email: String, password: String) throws -> User {
		let isKeyBackedUp = login.isKeyBackedUp == 1 ? true : false
		
		if KeyManagement.key == nil {
			guard true == KeyManagement.importKeyBundle(keyBundle: login.keyBundle, password: password) else {
				throw AuthWorkerError.cantImportKeyBundle
			}
			if isKeyBackedUp {
				KeyManagement.key = try self.crypto.getPrivateKey(password: password)
			}
			let pubKey = login.serverPublicKey
			KeyManagement.importServerPublicKey(pbk: pubKey)
		}
		
		let userId = Int(login.userId) ?? -1
		let user = User(token: login.token, userId: userId, isKeyBackedUp: isKeyBackedUp, homeFolder: login.homeFolder, email: email)
		self.db.updateUser(user: user)
		let info = AppInfo(lastSeen: 0, lastDelSeen: 0, spaceQuota: "1024", spaceUsed: "0", userId: user.userId)
		self.db.updateAppInfo(info: info)
		
		return user
	}
	
}

extension STAuthWorker {
	
	enum AuthWorkerError: IError {
		
		case passwordError
		case loginError
		case cantImportKeyBundle
		
		var message: String {
			switch self {
			case .passwordError:
				return "incorrect_password".localized
			case .loginError:
				return "nework_error_unknown_error".localized
			case .cantImportKeyBundle:
				return "nework_error_unknown_error".localized
			}
		}
		
	}
	
}
