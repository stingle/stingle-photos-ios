//
//  STAppSettings+Appearance.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/4/21.
//

import UIKit

extension STAppSettings {
    
    struct Appearance: Codable {
        
        var theme: Theme
        
        static var `default`: Appearance {
            let result = Appearance(theme: .system)
            return result
        }
        
        enum Theme: String, Codable, CaseIterable {
            case system = "system"
            case light = "light"
            case dark = "dark"
            
            var localized: String {
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

    }
        
}

extension STAppSettings.Appearance.Theme {
    
    var interfaceStyle: UIUserInterfaceStyle {
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
