//
//  STSecurityVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/15/21.
//

import Foundation

class STSecurityVM {
    
    lazy var security: STAppSettings.Security = {
        return STAppSettings.security
    }()
    
    func update(biometricAuthentication isOn: Bool) {
        self.security.authentication.touchID = isOn
        STAppSettings.security = self.security
    }
    
    func update(requireConfirmation isOn: Bool) {
        self.security.authentication.requireConfirmation = isOn
        STAppSettings.security = self.security
    }
    
    func update(disallowScreenshots isOn: Bool) {
        self.security.disallowScreenshots = isOn
        STAppSettings.security = self.security
    }
    
    func update(lockUpApp: STAppSettings.Security.LockUpApp) {
        self.security.lockUpApp = lockUpApp
        STAppSettings.security = self.security
    }
    
}
