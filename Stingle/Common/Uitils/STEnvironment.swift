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
    let appName: String
    let bundleIdentifier: String
    let appWebUrl: String = "https://stingle.org"
    let photoLibraryTrashAlbumName = "Stingle Trash"
    
	    
	static let current: STEnvironment = STEnvironment()
	
	private init() {
		guard let buildTypeName = Self.variable(named: "BUILD_TYPE") as? String, let buildType = BuildType(rawValue: buildTypeName), let baseUrl = Self.variable(named: "BASE_API_URL"), let bundleIdentifier = Self.variable(named: "CFBundleIdentifier") else {
			fatalError("Can't find configuration")
		}
		
        self.bundleIdentifier = bundleIdentifier as! String
		self.baseUrl = baseUrl as! String
		self.buildType = buildType
        self.appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String
	}
	
	static private func variable(named name: String) -> Any? {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict[name]
	}
	
}
