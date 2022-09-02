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
    
    private static let userDefaults = UserDefaults(suiteName: STEnvironment.current.groupAppFileSharingBundleId)
    private let defaultBaseUrl: String
    
    public var baseUrl: String {
        return Self.userDefaults?.value(forKey: "BASE_API_URL") as? String ?? self.defaultBaseUrl
    }
    
    public let buildType: BuildType
    public let appName: String
    public let productName: String
    public let bundleIdentifier: String
    public let appWebUrl: String = "https://stingle.org"
    public let photoLibraryTrashAlbumName = "Stingle Trash"
    public let appFileSharingBundleId: String
    public let groupAppFileSharingBundleId: String
    public let appIsExtension: Bool
	public static let current: STEnvironment = STEnvironment()
   
    
	private init() {
		guard let buildTypeName = Self.variable(named: "BUILD_TYPE") as? String, let buildType = BuildType(rawValue: buildTypeName), let baseUrl = Self.variable(named: "BASE_API_URL"), let bundleIdentifier = Self.variable(named: "APP_BUNDLE_ID"), let appFileSharingBundleId = Self.variable(named: "APP_FILE_SHARING_BUNDLE_ID") as? String, let productName = Self.variable(named: "APP_NAME") as? String else {
			fatalError("Can't find configuration")
		}
                
        self.appIsExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        self.productName = productName
        self.bundleIdentifier = bundleIdentifier as! String
		self.defaultBaseUrl = baseUrl as! String
		self.buildType = buildType
        self.appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String
        self.appFileSharingBundleId = appFileSharingBundleId
        self.groupAppFileSharingBundleId = "group." + self.appFileSharingBundleId
	}
	
    private static func variable(named name: String) -> Any? {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict[name]
	}
	
}

public extension STEnvironment {
    
    func setBaseUrl(url: URL?) {
        let userDefaults = UserDefaults(suiteName: self.groupAppFileSharingBundleId)
        userDefaults?.set(url?.absoluteString, forKey: "BASE_API_URL")
        userDefaults?.synchronize()
    }
    
}
