//
//  STBackupVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/3/21.
//

import Foundation
import StingleRoot

class STBackupVM {
    
    lazy var backup: STAppSettings.Backup = {
        return STAppSettings.current.backup
    }()
    
    func updateBackup(isEnabled: Bool) {
        self.backup.isEnabled = isEnabled
        STAppSettings.current.backup = self.backup
    }
    
    func updateBackup(isOnlyWiFi: Bool) {
        self.backup.isOnlyWiFi = isOnlyWiFi
        STAppSettings.current.backup = self.backup
    }
    
    func updateBackup(batteryLevel: Float) {
        self.backup.batteryLevel = batteryLevel
        STAppSettings.current.backup = self.backup
    }
    
}
