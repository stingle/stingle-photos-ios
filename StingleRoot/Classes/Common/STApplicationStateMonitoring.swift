//
//  ATApplicationStateObserver.swift
//  Kinodaran
//
//  Created by Khoren Asatryan on 21.07.22.
//  Copyright © 2022 Advanced Tech. All rights reserved.
//

import UIKit

class STApplicationStateMonitoring {
    
    typealias Event = ((UIApplication.State) -> Void)
    private var applicationState = UIApplication.shared.applicationState
    private var events = [String: Event]()
    private let queue = DispatchQueue.main
    
    init() {
        self.addNotifications()
    }
    
    //MARK: - Public methods
    
    @discardableResult
    func addObserver(chenging: @escaping Event) -> String {
        let identifier = UUID().uuidString
        self.queue.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            chenging(UIApplication.shared.applicationState)
            weakSelf.events[identifier] = chenging
        }
        return identifier
    }
    
    func removeObserver(identifier: String) {
        self.queue.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.events[identifier] = nil
        }
    }
    
    //MARK: - Private methods
    
    private func addNotifications() {
        self.addNotifications(for: UIApplication.willResignActiveNotification)
        self.addNotifications(for: UIApplication.didBecomeActiveNotification)
        self.addNotifications(for: UIApplication.didEnterBackgroundNotification)
        self.addNotifications(for: UIApplication.willEnterForegroundNotification)
    }
    
    private func addNotifications(for name: Notification.Name) {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(stateDidChange(notification:)), name: name, object: nil)
    }
    
    @objc private func stateDidChange(notification: Notification) {
        let new = UIApplication.shared.applicationState
        guard self.applicationState != new else {
            return
        }
        self.applicationState = new
        self.events.forEach { (obj) in
            obj.value(new)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
}
