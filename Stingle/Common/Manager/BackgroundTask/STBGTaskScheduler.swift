//
//  STBackgroundTask.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/22.
//

import Foundation
import BackgroundTasks
import UIKit

class STBGTaskScheduler {
    
    enum BackgroundIdentifie: String, CaseIterable {
        case autoImport = "org.stingle.photos.auto.import"
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
        let que = DispatchQueue(label: "AuotImporter.queue")
        self.scheduler.register(forTaskWithIdentifier: identifie.rawValue, using: que) { [weak self] task in
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
        print("")
    }
    
    func schedulerTask(didComplet schedulerTask: Task, isCompleted: Bool) {
        print("")
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
        
        deinit {
            print("")
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
        
        let autoImporter = STApplication.shared.auotImporter
        private(set) var isStarted = false
        
        override init(identifier: STBGTaskScheduler.BackgroundIdentifie) {
            super.init(identifier: identifier)
            self.autoImporter.add(self)
            
            
        }
        
        override func submit(scheduler: BGTaskScheduler) throws {
                        
            let request = BGProcessingTaskRequest(identifier: self.identifier.rawValue)
            request.requiresNetworkConnectivity = true
            request.requiresExternalPower = true
            request.earliestBeginDate = Date(timeIntervalSinceNow: 3)
                        
            try scheduler.submit(request)
            self.isStarted = false
            
        }
        
        var timer: Timer?
        
        
        override func resume(task: BGTask) {
            print("bbbbbbb resume BGTask")
            super.resume(task: task)
            guard !self.isStarted else {
                return
            }
            self.isStarted = true
//            guard self.autoImporter.canStartImport else {
//                self.endTask(isCompleted: true)
//                return
//            }
//            self.autoImporter.startImport()
            
            print3("bbbbbbbddddddddd")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.print3("bbbbbbbddddddddd")
            }
            
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(resume3), userInfo: nil, repeats: true)
            
        }
        
        var m: Int = .zero
        
        
        @objc func resume3(timer: Timer) {
            print("ddddddddd", m)
            m = m + Int(timer.timeInterval)
        }
        
        override func cancel() {
            super.cancel()
            print("bbbbbbb cancel BGTask")
            self.autoImporter.cancelImporting(end: nil)
        }
        
        func print3(_ sttring: String) {
            let date = Date()
            let calendar = Calendar.current

            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            let seconds = calendar.component(.second, from: date)
            
            print(hour, minutes, seconds, sttring)
        }
        
    }
    
    
    
}

extension STBGTaskScheduler.AutoImporter: IAuotImporterObserver {
    
    func auotImporter(didStart auotImporter: STImporter.AuotImporter) {
        
    }
    
    func auotImporter(didEnd auotImporter: STImporter.AuotImporter) {
        guard self.isStarted else {
            return
        }
//        self.endTask(isCompleted: true)
    }
    
}
