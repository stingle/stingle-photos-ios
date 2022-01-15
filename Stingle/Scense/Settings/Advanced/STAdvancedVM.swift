//
//  STAdvancedVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/8/21.
//

import Foundation

class STAdvancedVM {
    
    lazy var advanced: STAppSettings.Advanced = {
        return STAppSettings.current.advanced
    }()
    
    func update(cacheSize: STAppSettings.Advanced.CacheSize) {
        self.advanced.cacheSize = cacheSize
        STAppSettings.current.advanced = self.advanced
    }
    
    func removeCache() {
        STApplication.shared.fileSystem.removeCache()
    }
    
}
