//
//  STError.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/18/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

protocol IError: Error {
	
	/// User for user info  Default  returned "warning".localized
	var title: String? { get }
	
	/// User for user info. Default  returned localizedDescription
	var message: String { get }
	
	/// User for event analytics data and developer info
	var statusCode: Int { get }
	
	/// User for event analytics data
	var eventLogErrorType: String { get }
	
	var noInternetConnection: Bool { get }
	var isCancelled: Bool { get }
	var noExistingData: Bool { get }
	
	var userInfo: [String: Any] { get }
 
}

extension IError {
	
	var localizedDescription: String {
		return self.message
	}
	
	var title: String? {
		return "warning".localized
	}
	
	var statusCode: Int {
		return 0
	}
	
	var eventLogErrorType: String {
		return ""
	}
	
	var noInternetConnection: Bool {
		return false
	}
	
	var isCancelled: Bool {
		return false
	}
	
	var noExistingData: Bool {
		return false
	}
	
	var userInfo: [String: Any] {
		var params = [String: Any]()
		params["message"] = self.message
		params["statusCode"] = self.statusCode
		params["type"] = self.eventLogErrorType
		return params
	}
	
}
