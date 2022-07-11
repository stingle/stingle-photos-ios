//
//  STEnvironment.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/2/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

public struct STEnvironment {
	
    public enum BuildType: String {
		case dev = "Development"
		case prod = "Production"
	}
	
    public let buildType: BuildType
    public let baseUrl: String
    public let appName: String
    public let bundleIdentifier: String
    public let appWebUrl: String = "https://stingle.org"
    public let photoLibraryTrashAlbumName = "Stingle Trash"
    public let appFileSharingBundleId: String
    
    	    
	public static let current: STEnvironment = STEnvironment()
	
	private init() {
		guard let buildTypeName = Self.variable(named: "BUILD_TYPE") as? String, let buildType = BuildType(rawValue: buildTypeName), let baseUrl = Self.variable(named: "BASE_API_URL"), let bundleIdentifier = Self.variable(named: "CFBundleIdentifier"), let appFileSharingBundleId = Self.variable(named: "APP_FILE_SHARING_BUNDLE_ID") as? String else {
			fatalError("Can't find configuration")
		}
        		
        self.bundleIdentifier = bundleIdentifier as! String
		self.baseUrl = baseUrl as! String
		self.buildType = buildType
        self.appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String
        self.appFileSharingBundleId = appFileSharingBundleId
	}
	
    private static func variable(named name: String) -> Any? {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict[name]
	}
	
}
