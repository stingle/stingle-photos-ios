//
//  STAppSettings.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/9/21.
//

import Foundation

extension STAppSettings {
    
    fileprivate struct Constance {
        static let settingsKey = "settings"
        static let isDeleteFilesWhenMoving = "isDeleteFilesWhenMoving"
        static let security = "security"
        static let backup = "backup"
        static let appearance = "appearance"
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
    
    static var backup: Backup {
        set {
            let json = newValue.toJson()
            self.settings[Constance.backup] = json
        } get {
            guard let json = self.settings[Constance.backup], let result = Backup(from: json) else {
                return .default
            }
            return result
        }
    }
    
    static var appearance: Appearance {
        set {
            let json = newValue.toJson()
            self.settings[Constance.appearance] = json
        } get {
            guard let json = self.settings[Constance.appearance], let result = Appearance(from: json) else {
                return .default
            }
            return result
        }
    }
    
    static func logOut() {
        self.settings = [:]
    }
            
}
