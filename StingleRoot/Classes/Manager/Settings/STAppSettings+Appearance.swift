//
//  STAppSettings+Appearance.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/4/21.
//

import UIKit

extension STAppSettings {
    
    public struct Appearance: Codable {
        
        public var theme: Theme
        
        static public  var `default`: Appearance {
            let result = Appearance(theme: .system)
            return result
        }
        
        public enum Theme: String, Codable, CaseIterable {
            case system = "system"
            case light = "light"
            case dark = "dark"
            
            public var localized: String {
                switch self {
                case .system:
                    return "follow_system".localized
                case .light:
                    return "light".localized
                case .dark:
                    return "dark".localized
                }
            }
        }
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.theme != rhs.theme
        }

    }
        
}

extension STAppSettings.Appearance.Theme {
    
    public var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
}
