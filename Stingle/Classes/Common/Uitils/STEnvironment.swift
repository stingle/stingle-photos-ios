//
//  STEnvironment.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/2/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

struct STEnvironment {
	
	enum BuildType: String {
		case dev = "Development"
		case prod = "Production"
	}
	
	let buildType: BuildType
	let baseUrl: String
	
	static let current: STEnvironment = STEnvironment()
	
	
	private init() {
		guard let buildTypeName = Self.variable(named: "BUILD_TYPE"), let buildType = BuildType(rawValue: buildTypeName),
			  let baseUrl = Self.variable(named: "BASE_API_URL") else {
			//	BASE_API_URL = "https://api.stingle.org/v2"
			//	BuildType = "Production"
			fatalError("Can't find configuration")
		}
		
		self.baseUrl = baseUrl
		self.buildType = buildType
	}
	
	static private func variable(named name: String) -> String? {
		let processInfo = ProcessInfo.processInfo
		guard let value = processInfo.environment[name] else {
			return nil
		}
		return value
	}
	
}
