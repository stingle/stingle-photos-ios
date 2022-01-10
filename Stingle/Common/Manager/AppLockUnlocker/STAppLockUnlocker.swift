//
//  STAppLockUnlocker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/10/22.
//

import UIKit

protocol IAppLockUnlockerObserver: AnyObject {
    func appLockUnlocker(didLockApp lockUnlocker: STAppLockUnlocker)
    func appLockUnlocker(didUnlockApp lockUnlocker: STAppLockUnlocker)
}

extension IAppLockUnlockerObserver {
    func appLockUnlocker(didLockApp lockUnlocker: STAppLockUnlocker) {}
    func appLockUnlocker(didUnlockApp lockUnlocker: STAppLockUnlocker) {}
}

class STAppLockUnlocker {
    
    enum AppLockState {
        case unknown
        case locked
        case unlocked
    }
    
    let locker = Locker()
    let unLocker = UnLocker()
    
    private(set) var state = AppLockState.unknown
    
    private let observer = STObserverEvents<IAppLockUnlockerObserver>()
    
    init() {
        self.locker.delegate = self
        self.unLocker.delegate = self
    }
    
    func add(_ observer: IAppLockUnlockerObserver) {
        self.observer.addObject(observer)
    }
    
    func remove(_ observer: IAppLockUnlockerObserver) {
        self.observer.removeObject(observer)
    }
    
}

extension STAppLockUnlocker: LockerDelegate, UnLockerDelegate {
    
    func appLocker(didLockApp locker: Locker) {
        self.state = .locked
        self.observer.forEach { [weak self] observer in
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                observer.appLockUnlocker(didLockApp: weakSelf)
            }
        }
    }
    
    func appUnLocker(didUnlockApp locker: UnLocker) {
        self.state = .unlocked
        self.observer.forEach { [weak self] observer in
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                observer.appLockUnlocker(didUnlockApp: weakSelf)
            }
        }
    }
    
}

fileprivate protocol LockerDelegate: AnyObject {
    func appLocker(didLockApp locker: STAppLockUnlocker.Locker)
}

extension STAppLockUnlocker {
    
    class Locker {
        
        private var resignActiveDate: Date?
        private var timer: Timer?
        
        weak fileprivate var delegate: LockerDelegate?
            
        init() {
            self.addNotifications()
        }
        
        func lockApp(showBiometricUnlocer: Bool) {
            guard STApplication.shared.utils.isLogedIn() else {
                return
            }
            STKeyManagement.key = nil
            STUnlockAppVC.show(showBiometricUnlocer: showBiometricUnlocer)
            self.delegate?.appLocker(didLockApp: self)
        }
            
        //MARK: - Private
        
        private func addNotifications() {
            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(willResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
            center.addObserver(self, selector: #selector(didActivate(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        
        @objc private func didActivate(_ notification: Notification) {
            let timeInterval = STAppSettings.current.security.lockUpApp.timeInterval
            guard let resignActiveDate = self.resignActiveDate, resignActiveDate.distance(to: Date()) >= timeInterval  else {
                return
            }
            self.lockApp(showBiometricUnlocer: true)
        }
         
        @objc private func willResignActive(_ notification: Notification) {
            self.resignActiveDate = Date()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
}

fileprivate protocol UnLockerDelegate: AnyObject {
    func appUnLocker(didUnlockApp locker: STAppLockUnlocker.UnLocker)
}

extension STAppLockUnlocker {
    
    class UnLocker {
        
        weak fileprivate var delegate: UnLockerDelegate?
        
        lazy private var biometric: STBiometricAuthServices = {
            return STBiometricAuthServices()
        }()
        
        var biometricAuthServicesType: STBiometricAuthServices.ServicesType {
            return self.biometric.type
        }
        
        var canUnlockAppBiometric: Bool {
            return self.biometric.canUnlockApp
        }
        
        func unlockAppBiometric(success: @escaping () -> Void, failure: @escaping (IError?) -> Void) {
            self.biometric.unlockApp { _ in
                success()
                self.appDidUnlocked()
            } failure: { error in
                failure(error)
            }
        }
        
        func unlockApp(password: String?, completion: @escaping (IError?) -> Void) {
            guard let password = password, !password.isEmpty else {
                completion(UnlockAppVMError.passwordIsNil)
                return
            }
            do {
                try self.biometric.unlockApp(password: password)
                completion(nil)
                self.appDidUnlocked()
            } catch {
                completion(UnlockAppVMError.passwordIncorrect)
            }
        }
        
        //MARK: -
        
        private func appDidUnlocked() {
            self.delegate?.appUnLocker(didUnlockApp: self)
        }
        
    }
    
}

extension STAppLockUnlocker.UnLocker {
    
    private enum UnlockAppVMError: IError {
        
        case passwordIsNil
        case passwordIncorrect
        
        var message: String {
            switch self {
            case .passwordIsNil:
                return "error_empty_password".localized
            case .passwordIncorrect:
                return "error_password_not_valed".localized
            }
        }
        
    }
    
}
