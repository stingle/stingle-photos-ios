//
//  STAppSettings.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/9/21.
//

import Foundation

extension STAppSettings {
    
    fileprivate struct Constance {
        static let settingsKey = "settingsKey"
        static let isDeleteFilesWhenMoving = "isDeleteFilesWhenMoving"
        static let security = "securityKey"
    }
    
}

class STAppSettings {
    
    static private let userDefaults = UserDefaults.standard
        
    static var settings: [String: Any] {
        set {
            self.userDefaults.setValue(newValue, forKey: Constance.settingsKey)
        } get {
            return self.userDefaults.dictionary(forKey: Constance.settingsKey) ?? [String: Any]()
        }
    }
    
    static var isDeleteFilesWhenMoving: Bool {
        set {
            self.settings[Constance.isDeleteFilesWhenMoving] = newValue
        } get {
            return self.settings[Constance.isDeleteFilesWhenMoving] as? Bool ?? true
        }
    }
    
    static var security: Security {
        set {
            let json = newValue.toJson()
            self.settings[Constance.security] = json
        } get {
            guard let json = self.settings[Constance.security], let result = Security(from: json) else {
                return .default
            }
            return result
        }
        
    }
            
}
