//
//  STBackupVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/3/21.
//

import Foundation

class STBackupVM {
    
    lazy var backup: STAppSettings.Backup = {
        return STAppSettings.backup
    }()
    
    func updateBackup(isEnabled: Bool) {
        self.backup.isEnabled = isEnabled
        STAppSettings.backup = self.backup
    }
    
    func updateBackup(isOnlyWiFi: Bool) {
        self.backup.isOnlyWiFi = isOnlyWiFi
        STAppSettings.backup = self.backup
    }
    
    func updateBackup(batteryLevel: Float) {
        self.backup.batteryLevel = batteryLevel
        STAppSettings.backup = self.backup
    }
    
}
