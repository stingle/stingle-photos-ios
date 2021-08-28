//
//  STAppLocker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/21/21.
//

import UIKit

class STAppLocker {
    
    private var resignActiveDate: Date?
    
    private var timer3: STRepeatingTimer?
    private var timer: Timer?
    private var taskIdentifier: UIBackgroundTaskIdentifier?
        
    init() {
        self.addNotifications()
    }
        
    //MARK: - Private
    
    private func addNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(willResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)        
        center.addObserver(self, selector: #selector(didActivate(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func didActivate(_ notification: Notification) {
        let timeInterval = STAppSettings.security.lockUpApp.timeInterval
        guard STApplication.shared.isLogedIn(), let resignActiveDate = self.resignActiveDate, resignActiveDate.distance(to: Date()) >= timeInterval  else {
            return
        }
        KeyManagement.key = nil
        STUnlockAppVC.show()
    }
     
    @objc private func willResignActive(_ notification: Notification) {
        self.resignActiveDate = Date()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}


class STRepeatingTimer {
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    var eventHandler: (() -> Void)?
    let timeInterval: TimeInterval
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
                
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
