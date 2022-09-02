//
//  STAppSettings+Import.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/5/22.
//

import Foundation

public extension STAppSettings {
    
    struct Import: Codable {
        
        public var isAutoImportEnable: Bool
        public var isDeleteOriginalFilesAfterAutoImport: Bool
        public var manualImportDeleteFilesType: ManualImportDeleteFilesType
        
        static var `default`: Import {
            let result = Import(isAutoImportEnable: false, isDeleteOriginalFilesAfterAutoImport: false, manualImportDeleteFilesType: .askEveryTime)
            return result
        }
        
        public enum ManualImportDeleteFilesType: String, Codable, CaseIterable {
            case never = "never"
            case askEveryTime = "askEveryTime"
            case always = "always"
            
            public var localized: String {
                switch self {
                case .never:
                    return "never".localized
                case .askEveryTime:
                    return "ask_every_time".localized
                case .always:
                    return "always".localized
                }
            }
        }
        
        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.isAutoImportEnable != rhs.isAutoImportEnable || rhs.isDeleteOriginalFilesAfterAutoImport != rhs.isDeleteOriginalFilesAfterAutoImport || rhs.manualImportDeleteFilesType != rhs.manualImportDeleteFilesType
        }
        
    }
    
}
