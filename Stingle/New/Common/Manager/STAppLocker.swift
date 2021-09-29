//
//  STAppLocker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/21/21.
//

import UIKit

class STAppLocker {
    
    private var resignActiveDate: Date?
    private var timer: Timer?
    private var taskIdentifier: UIBackgroundTaskIdentifier?
        
    init() {
        self.addNotifications()
    }
    
    func lockApp() {
        guard STApplication.shared.utils.isLogedIn() else {
            return
        }
        STKeyManagement.key = nil
        STUnlockAppVC.show()
    }
        
    //MARK: - Private
    
    private func addNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(willResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)        
        center.addObserver(self, selector: #selector(didActivate(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func didActivate(_ notification: Notification) {
        let timeInterval = STAppSettings.security.lockUpApp.timeInterval
        guard let resignActiveDate = self.resignActiveDate, resignActiveDate.distance(to: Date()) >= timeInterval  else {
            return
        }
        self.lockApp()
    }
     
    @objc private func willResignActive(_ notification: Notification) {
        self.resignActiveDate = Date()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
