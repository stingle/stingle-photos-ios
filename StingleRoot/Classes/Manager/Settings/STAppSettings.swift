//
//  STAppSettings.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/9/21.
//

import Foundation

public protocol ISettingsObserver: AnyObject {
    
    func appSettings(didChange settings: STAppSettings, isDeleteFilesWhenMoving: Bool)
    func appSettings(didChange settings: STAppSettings, security: STAppSettings.Security)
    func appSettings(didChange settings: STAppSettings, backup: STAppSettings.Backup)
    func appSettings(didChange settings: STAppSettings, appearance: STAppSettings.Appearance)
    func appSettings(didChange settings: STAppSettings, advanced: STAppSettings.Advanced)
    func appSettings(didChange settings: STAppSettings, import: STAppSettings.Import)
  
}

public extension ISettingsObserver {
    
    func appSettings(didChange settings: STAppSettings, isDeleteFilesWhenMoving: Bool) {}
    func appSettings(didChange settings: STAppSettings, security: STAppSettings.Security) {}
    func appSettings(didChange settings: STAppSettings, backup: STAppSettings.Backup) {}
    func appSettings(didChange settings: STAppSettings, appearance: STAppSettings.Appearance) {}
    func appSettings(didChange settings: STAppSettings, advanced: STAppSettings.Advanced) {}
    func appSettings(didChange settings: STAppSettings, import: STAppSettings.Import) {}
    
}

fileprivate extension STAppSettings {
    
    struct Constance {
        static let settingsKey = "settings"
        static let isDeleteFilesWhenMoving = "isDeleteFilesWhenMoving"
        static let security = "security"
        static let backup = "backup"
        static let appearance = "appearance"
        static let advanced = "advanced"
        static let `import` = "import"
    }
    
}

public class STAppSettings {
    
    static public let current: STAppSettings = STAppSettings()
    static private let userDefaults = STAppSettings.createUserDefaults()
    
    private var observers = STObserverEvents<ISettingsObserver>()
            
    static private var settings: [String: Any] {
        set {
            self.userDefaults.setValue(newValue, forKey: Constance.settingsKey)
            self.userDefaults.synchronize()
        } get {
            return self.userDefaults.dictionary(forKey: Constance.settingsKey) ?? [String: Any]()
        }
    }
    
    public var isDeleteFilesWhenMoving: Bool {
        set {
            let oldValue: Bool = self.isDeleteFilesWhenMoving
            Self.settings[Constance.isDeleteFilesWhenMoving] = newValue
            if oldValue != newValue {
                self.observers.forEach { observer in
                    observer.appSettings(didChange: self, isDeleteFilesWhenMoving: newValue)
                }
            }
        } get {
            return Self.settings[Constance.isDeleteFilesWhenMoving] as? Bool ?? true
        }
    }
    
    public var security: Security {
        set {
            let oldValue = self.security
            let json = newValue.toJson()
            Self.settings[Constance.security] = json
            if oldValue != newValue {
                self.observers.forEach { observer in
                    observer.appSettings(didChange: self, security: newValue)
                }
            }
        } get {
            guard let json = Self.settings[Constance.security], let result = Security(from: json) else {
                return .default
            }
            return result
        }
    }
    
    public var backup: Backup {
        set {
            let oldValue = self.backup
            let json = newValue.toJson()
            Self.settings[Constance.backup] = json
            if oldValue != newValue {
                self.observers.forEach { observer in
                    observer.appSettings(didChange: self, backup: newValue)
                }
            }
        } get {
            guard let json = Self.settings[Constance.backup], let result = Backup(from: json) else {
                return .default
            }
            return result
        }
    }
    
    public var appearance: Appearance {
        set {
            let oldValue = self.appearance
            let json = newValue.toJson()
            Self.settings[Constance.appearance] = json
            if oldValue != newValue {
                self.observers.forEach { observer in
                    observer.appSettings(didChange: self, appearance: newValue)
                }
            }
        } get {
            guard let json = Self.settings[Constance.appearance], let result = Appearance(from: json) else {
                return .default
            }
            return result
        }
    }
    
    public var advanced: Advanced {
        set {
            let oldValue = self.advanced
            let json = newValue.toJson()
            Self.settings[Constance.advanced] = json
            
            if oldValue != newValue {
                self.observers.forEach { observer in
                    observer.appSettings(didChange: self, advanced: newValue)
                }
            }
        } get {
            guard let json = Self.settings[Constance.advanced], let result = Advanced(from: json) else {
                return .default
            }
            return result
        }
    }
    
    public var `import`: Import {
        set {
            let oldValue = self.import
            let json = newValue.toJson()
            Self.settings[Constance.import] = json
            
            if oldValue != newValue {
                self.observers.forEach { observer in
                    observer.appSettings(didChange: self, import: newValue)
                }
            }
        } get {
            guard let json = Self.settings[Constance.import], let result = Import(from: json) else {
                return .default
            }
            return result
        }
    }
    
    public var isExistImportInfo: Bool {
        return Self.settings[Constance.import] != nil
    }
    
    public func addObserver(_ lisner: ISettingsObserver) {
        self.observers.addObject(lisner)
    }
    
    public func removeObserver(_ lisner: ISettingsObserver) {
        self.observers.removeObject(lisner)
    }
    
    public func logOut() {
        Self.settings = [:]
    }
            
}

extension STAppSettings {
        
    class func migrate() {
        let environment = STEnvironment.current
        guard !environment.appRunIsExtension else {
            return
        }
        let userDefaults = UserDefaults.standard
        let groupUserDefaults =  UserDefaults(suiteName: "group." + environment.appFileSharingBundleId)
        if let dic = userDefaults.dictionary(forKey: Constance.settingsKey), !dic.isEmpty  {
            groupUserDefaults?.set(dic, forKey: Constance.settingsKey)
            userDefaults.set(nil, forKey: Constance.settingsKey)
            userDefaults.synchronize()
            groupUserDefaults?.synchronize()
        }
    }
    
    private class func createUserDefaults() -> UserDefaults {
        let environment = STEnvironment.current
        guard let uefaults = UserDefaults(suiteName: "group." + environment.appFileSharingBundleId) else {
            STLogger.log(logMessage: "create app group")
            fatalError("create app group")
        }
        return uefaults
    }
    
}
