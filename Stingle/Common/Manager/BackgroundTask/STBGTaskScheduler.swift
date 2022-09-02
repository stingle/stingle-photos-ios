//
//  STBackgroundTask.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/22.
//

import Foundation
import BackgroundTasks
import StingleRoot
import UIKit

class STBGTaskScheduler {
    
    enum BackgroundIdentifie: String, CaseIterable {
        case autoImport = "org.stingle.photos.auto.import"
        
        var dispatchQueue: DispatchQueue {
            switch self {
            case .autoImport:
                return STApplication.shared.autoImporter.dispatchQueue
            }
        }
    }
    
    static let shared = STBGTaskScheduler()
    private(set) var isStarted: Bool = false
    private var tasks = Set<Task>()
    private let scheduler = BGTaskScheduler.shared
    
    private init() {}
    
    func start() {
        self.addNotifications()
        guard !self.isStarted else {
            return
        }
        self.isStarted = true
        self.register()
    }
    
    //MARK: - Private methods
    
    private func addNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    private func cancelAllTask() {
        self.scheduler.cancelAllTaskRequests()
        self.tasks.forEach { task in
            task.cancel()
        }
    }
    
    private func register() {
        BackgroundIdentifie.allCases.forEach { identifie in
            self.registerTask(identifie: identifie)
        }
    }
    
    private func registerTask(identifie: BackgroundIdentifie) {
        self.scheduler.register(forTaskWithIdentifier: identifie.rawValue, using: identifie.dispatchQueue) { [weak self] task in
            guard let id = BackgroundIdentifie(rawValue: task.identifier) else { return  }
            let myTask = self?.tasks.first(where: { $0.identifier == id })
            myTask?.resume(task: task)
        }
        self.createTask(identifie: identifie)
    }
    
    private func createTask(identifie: BackgroundIdentifie) {
        switch identifie {
        case .autoImport:
            let task = AutoImporter(identifier: identifie)
            task.delegate = self
            self.tasks.insert(task)
        }
    }
    
    //MARK: - Private notifiication
    
    @objc private func applicationDidBecomeActive() {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        self.cancelAllTask()
    }
    
    @objc private func appDidEnterBackground() {
        guard UIApplication.shared.applicationState == .background else {
            return
        }
        self.tasks.forEach { task in
            try? task.submit(scheduler: self.scheduler)
        }
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension STBGTaskScheduler: STBGSchedulerTaskDelegate {
    
    func schedulerTask(didCanceled schedulerTask: Task) {
    }
    
    func schedulerTask(didComplet schedulerTask: Task, isCompleted: Bool) {
    }
    
}

protocol STBGSchedulerTaskDelegate: AnyObject {
    
    func schedulerTask(didCanceled schedulerTask: STBGTaskScheduler.Task)
    func schedulerTask(didComplet schedulerTask: STBGTaskScheduler.Task, isCompleted: Bool)
    
}

extension STBGTaskScheduler {
    
    class Task {
        
        private(set) var task: BGTask?
        let identifier: STBGTaskScheduler.BackgroundIdentifie
        
        weak var delegate: STBGSchedulerTaskDelegate?
        
        init(identifier: STBGTaskScheduler.BackgroundIdentifie) {
            self.identifier = identifier
        }
                        
        func submit(scheduler: BGTaskScheduler) throws {
            throw STError.canceled
        }
        
        func resume(task: BGTask) {
            self.task = task
            self.task?.expirationHandler = { [weak self] in
                self?.cancel()
            }
        }
        
        //MARK: - Internal methods
        
        internal func cancel() {
            guard self.task != nil else {
                return
            }
            self.delegate?.schedulerTask(didCanceled: self)
            self.task = nil
        }
        
        internal func endTask(isCompleted: Bool) {
            guard self.task != nil else {
                return
            }
            self.task?.setTaskCompleted(success: isCompleted)
            self.delegate?.schedulerTask(didComplet: self, isCompleted: isCompleted)
            self.task = nil
        }
    
    }
    
}

extension STBGTaskScheduler.Task: Hashable {
    
    static func == (lhs: STBGTaskScheduler.Task, rhs: STBGTaskScheduler.Task) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }
    
}

extension STBGTaskScheduler {
    
    class AutoImporter: Task {
        
        let bgImptortTimeInterval: TimeInterval = 20 * 60
        
        let autoImporter = STApplication.shared.autoImporter
        private(set) var isStarted = false
        
        override init(identifier: STBGTaskScheduler.BackgroundIdentifie) {
            super.init(identifier: identifier)
            self.autoImporter.add(self)
        }
        
        override func submit(scheduler: BGTaskScheduler) throws {
            let request = BGProcessingTaskRequest(identifier: self.identifier.rawValue)
            request.requiresNetworkConnectivity = true
            request.requiresExternalPower = true
            request.earliestBeginDate = Date(timeIntervalSinceNow: self.bgImptortTimeInterval)
            try scheduler.submit(request)
            self.isStarted = false
        }
        
        override func resume(task: BGTask) {
            try? self.submit(scheduler: BGTaskScheduler.shared)
            guard !self.isStarted else {
                return
            }
            super.resume(task: task)
            self.isStarted = true
            guard self.autoImporter.canStartImport else {
                self.endTask(isCompleted: true)
                return
            }
            self.autoImporter.startImport()
        }
        
        override func cancel() {
            super.cancel()
            self.autoImporter.cancelImporting(end: nil)
        }
    }
        
}

extension STBGTaskScheduler.AutoImporter: IAutoImporterObserver {
    
    func autoImporter(didStart autoImporter: STImporter.AutoImporter) {}
    
    func autoImporter(didEnd autoImporter: STImporter.AutoImporter) {
        guard self.isStarted else {
            return
        }
        self.endTask(isCompleted: true)
    }
    
}
