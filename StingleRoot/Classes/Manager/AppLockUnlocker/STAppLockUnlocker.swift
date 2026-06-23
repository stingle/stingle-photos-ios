//
//  STAppLockUnlocker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/10/22.
//

import UIKit

public protocol IAppLockUnlockerObserver: AnyObject {
    func appLockUnlocker(didLockApp lockUnlocker: STAppLockUnlocker)
    func appLockUnlocker(didUnlockApp lockUnlocker: STAppLockUnlocker)
}

public extension IAppLockUnlockerObserver {
    func appLockUnlocker(didLockApp lockUnlocker: STAppLockUnlocker) {}
    func appLockUnlocker(didUnlockApp lockUnlocker: STAppLockUnlocker) {}
}

public class STAppLockUnlocker {
    
    public enum AppLockState {
        case unknown
        case locked
        case unlocked
    }
    
    public let locker = Locker()
    public let unLocker = UnLocker()
    private var myState = AppLockState.unknown
    
    public typealias CallBackLock = ((_ appIsLocked: Bool, _ isAutoLock: Bool) -> Void)
    
    private var callBackLock: CallBackLock?
    
    public var state: AppLockState {
        switch self.myState {
        case .unknown:
            return STKeyManagement.key == nil ? .locked : .unlocked
        default:
            return self.myState
        }
    }
    
    private let observer = STObserverEvents<IAppLockUnlockerObserver>()
    
    public init(callBackLock: CallBackLock?) {
        self.callBackLock = callBackLock
        self.locker.delegate = self
        self.unLocker.delegate = self
    }
    
    public func add(_ observer: IAppLockUnlockerObserver) {
        self.observer.addObject(observer)
    }
    
    public func remove(_ observer: IAppLockUnlockerObserver) {
        self.observer.removeObject(observer)
    }
    
    
    deinit {
        self.callBackLock = nil
    }
}

extension STAppLockUnlocker: LockerDelegate, UnLockerDelegate {
    
    func appLocker(didLockApp locker: Locker, isAutoLock: Bool) {
        self.myState = .locked
        self.observer.forEach { [weak self] observer in
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                observer.appLockUnlocker(didLockApp: weakSelf)
            }
        }
        self.callBackLock?(true, isAutoLock)
    }
    
    func appUnLocker(didUnlockApp locker: UnLocker) {
        self.myState = .unlocked
        self.observer.forEach { [weak self] observer in
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                observer.appLockUnlocker(didUnlockApp: weakSelf)
            }
        }
        self.callBackLock?(false, false)
    }
    
}

fileprivate protocol LockerDelegate: AnyObject {
    func appLocker(didLockApp locker: STAppLockUnlocker.Locker, isAutoLock: Bool)
}

public extension STAppLockUnlocker {
    
    class Locker {
        
        private var resignActiveDate: Date?
        private var timer: Timer?
        private var pauseStartDate: Date?

        /// Upper bound on how long the camera pause may suppress auto-lock. Acts as a watchdog: if the
        /// flag is left set (e.g. the camera VC is torn down without `viewDidDisappear` firing), a
        /// later foreground event will lock anyway instead of leaving the app permanently unlockable.
        private let maxAutoLockPauseInterval: TimeInterval = 5 * 60

        /// When true, foreground re-entry won't auto-lock. Set while the camera is
        /// presented so a brief backgrounding (e.g. a permission prompt) doesn't
        /// tear down an active capture session. Clearing it re-evaluates the lock so a
        /// timeout that elapsed while paused (e.g. the user backgrounded on the camera
        /// then returned and left the camera tab) is not permanently skipped.
        public var isAutoLockPaused: Bool = false {
            didSet {
                if !oldValue && isAutoLockPaused {
                    self.pauseStartDate = Date()
                } else if oldValue && !isAutoLockPaused {
                    self.pauseStartDate = nil
                    self.evaluateAutoLockIfNeeded(ignorePause: true)
                }
            }
        }

        weak fileprivate var delegate: LockerDelegate?
            
        init() {
            self.addNotifications()
        }
        
        public func lockApp() {
            self.appDidLock(isAutoLock: false)
        }
            
        //MARK: - Private
        
        private func addNotifications() {
            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(willResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
            center.addObserver(self, selector: #selector(didActivate(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        
        public func appDidLock(isAutoLock: Bool) {
            guard STApplication.shared.utils.isLogedIn() else {
                return
            }
            STKeyManagement.key = nil
            self.delegate?.appLocker(didLockApp: self, isAutoLock: isAutoLock)
        }
        
        @objc private func didActivate(_ notification: Notification) {
            self.evaluateAutoLockIfNeeded(ignorePause: false)
        }

        private func evaluateAutoLockIfNeeded(ignorePause: Bool) {
            if !ignorePause && self.isAutoLockPaused {
                // Honor the camera pause, unless it has been held past the watchdog cap.
                if let pauseStart = self.pauseStartDate, pauseStart.distance(to: Date()) < self.maxAutoLockPauseInterval {
                    return
                }
            }
            let timeInterval = STAppSettings.current.security.lockUpApp.timeInterval
            guard let resignActiveDate = self.resignActiveDate, resignActiveDate.distance(to: Date()) >= timeInterval  else {
                return
            }
            self.appDidLock(isAutoLock: true)
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

public extension STAppLockUnlocker {
    
    class UnLocker {
        
        weak fileprivate var delegate: UnLockerDelegate?
        
        lazy private var biometric: STBiometricAuthServices = {
            return STBiometricAuthServices()
        }()
        
        public var biometricAuthServicesType: STBiometricAuthServices.ServicesType {
            return self.biometric.type
        }
        
        public var canUnlockAppBiometric: Bool {
            return self.biometric.canUnlockApp
        }

        public var isBiometricConfigured: Bool {
            return self.biometric.isBiometricConfigured
        }
        
        public func unlockAppBiometric(success: @escaping () -> Void, failure: @escaping (IError?) -> Void) {
            self.biometric.unlockApp { [weak self] _ in
                success()
                self?.appDidUnlocked()
            } failure: { error in
                failure(error)
            }
        }
        
        public func unlockApp(password: String?, completion: @escaping (IError?) -> Void) {
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
        
        //MARK: - Private
        
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
