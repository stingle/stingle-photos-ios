//
//  AppDelegate.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/3/21.
//

import UIKit
import StingleRoot

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
            STLogger.log(info: "baseUrl, \(STEnvironment.current.baseUrl)")
            STLogger.log(info: "bundleIdentifier, \(STEnvironment.current.bundleIdentifier)")
            STMainThreadWatchdog.shared.start()
        #endif

        // Enable battery monitoring as early as possible (it was previously only enabled by
        // the main UI). Without it, `UIDevice.current.batteryLevel` is -1 on a cold
        // background launch, which fails the upload battery gate and silently blocks
        // background uploads. See `STApplication.Utils.canUploadFile()`.
        UIDevice.current.isBatteryMonitoringEnabled = true

        // BGTaskScheduler launch handlers MUST be registered before
        // `didFinishLaunchingWithOptions` returns. Deferring this via
        // `DispatchQueue.main.async` registered them on the next run-loop tick — too late —
        // so iOS never launched the app to run background auto-import. Register synchronously.
        STBGTaskScheduler.shared.start()

        DispatchQueue.main.async {
            STApplication.shared.delegate = self
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }

    // iOS relaunches the app (or wakes it) to deliver completion events for the background
    // upload `URLSession` (`sessionSendsLaunchEvents = true`). We hand the system completion
    // handler to the dispatcher so it can be invoked once the session finishes processing its
    // events — otherwise background upload completions aren't finalized until the next launch.
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        STNetworkDispatcher.handleEventsForBackgroundURLSession(identifier: identifier, completionHandler: completionHandler)
    }

}

extension AppDelegate: STApplicationDelegate {
    
    func application(appDidLogouted app: STApplication, appInUnauthorized: Bool) {
        STMainVC.show(appInUnauthorized: appInUnauthorized)
    }
    
    func application(appDidDeleteAccount app: STApplication) {
        STMainVC.show(appInUnauthorized: false)
    }
    
    func application(appDidLoced app: STApplication, isAutoLock: Bool) {
        STUnlockAppVC.show(showBiometricUnlocer: isAutoLock)
    }

}

#if DEBUG
/// DEBUG-only diagnostic. A background timer tracks how long the main thread has been unresponsive;
/// when it crosses a threshold it SUSPENDS the main thread, walks its call stack, resumes it, and
/// logs a symbolicated backtrace — so we see exactly what the main thread is stuck in during a hang.
/// Remove once the freeze is diagnosed.
final class STMainThreadWatchdog {

    static let shared = STMainThreadWatchdog()

    private let queue = DispatchQueue(label: "org.stingle.perf.watchdog")
    private var timer: DispatchSourceTimer?
    private var mainMachThread: thread_t = 0
    private let lock = NSLock()
    private var lastAck = CFAbsoluteTimeGetCurrent()
    private var lastCapture: CFAbsoluteTime = 0
    private let stallThreshold: CFTimeInterval = 0.4

    func start() {
        self.mainMachThread = mach_thread_self()   // called on main → this is the main thread
        let timer = DispatchSource.makeTimerSource(queue: self.queue)
        timer.schedule(deadline: .now() + 2, repeating: .milliseconds(150))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let now = CFAbsoluteTimeGetCurrent()
            self.lock.lock()
            let elapsed = now - self.lastAck
            // Sample the hung main thread at most ~once/second so a multi-second hang yields a few
            // backtraces (a mini-profile) rather than one possibly-unlucky sample.
            let shouldCapture = elapsed > self.stallThreshold && (now - self.lastCapture) > 1.0
            if shouldCapture { self.lastCapture = now }
            self.lock.unlock()
            if elapsed > self.stallThreshold {
                NSLog("[STPERF] ⚠️ MAIN-THREAD STALL %.3fs", elapsed)
                if shouldCapture { self.captureMainBacktrace(elapsed: elapsed) }
            }
            DispatchQueue.main.async {
                self.lock.lock()
                self.lastAck = CFAbsoluteTimeGetCurrent()
                self.lock.unlock()
            }
        }
        timer.resume()
        self.timer = timer
    }

    // Strip ARM pointer-authentication / top bits so addresses resolve in dladdr.
    private func strip(_ a: UInt) -> UInt { return a & 0x0000_FFFF_FFFF_FFFF }

    private func readWord(_ addr: UInt) -> UInt? {
        var value: UInt = 0
        var outSize: vm_size_t = 0
        let kr = withUnsafeMutablePointer(to: &value) { p in
            vm_read_overwrite(mach_task_self_, vm_address_t(addr), vm_size_t(MemoryLayout<UInt>.size), vm_address_t(UInt(bitPattern: p)), &outSize)
        }
        return kr == KERN_SUCCESS ? value : nil
    }

    private func captureMainBacktrace(elapsed: CFTimeInterval) {
        let thread = self.mainMachThread
        guard thread != 0, thread_suspend(thread) == KERN_SUCCESS else { return }
        var frames = [UInt]()
        #if arch(arm64)
        var state = arm_thread_state64_t()
        var count = mach_msg_type_number_t(MemoryLayout<arm_thread_state64_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &state) { sp in
            sp.withMemoryRebound(to: natural_t.self, capacity: Int(count)) { ip in
                thread_get_state(thread, thread_state_flavor_t(ARM_THREAD_STATE64), ip, &count)
            }
        }
        if kr == KERN_SUCCESS {
            frames.append(self.strip(UInt(state.__pc)))
            frames.append(self.strip(UInt(state.__lr)))
            var fp = self.strip(UInt(state.__fp))
            var depth = 0
            while fp != 0, depth < 40 {
                guard let nextFp = self.readWord(fp), let ret = self.readWord(fp + 8) else { break }
                let r = self.strip(ret)
                if r != 0 { frames.append(r) }
                let n = self.strip(nextFp)
                if n <= fp { break }
                fp = n
                depth += 1
            }
        }
        #elseif arch(x86_64)
        var state = x86_thread_state64_t()
        var count = mach_msg_type_number_t(MemoryLayout<x86_thread_state64_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &state) { sp in
            sp.withMemoryRebound(to: natural_t.self, capacity: Int(count)) { ip in
                thread_get_state(thread, thread_state_flavor_t(x86_THREAD_STATE64), ip, &count)
            }
        }
        if kr == KERN_SUCCESS {
            frames.append(UInt(state.__rip))
            var fp = UInt(state.__rbp)
            var depth = 0
            while fp != 0, depth < 40 {
                guard let nextFp = self.readWord(fp), let ret = self.readWord(fp + 8) else { break }
                if ret != 0 { frames.append(ret) }
                if nextFp <= fp { break }
                fp = nextFp
                depth += 1
            }
        }
        #endif
        thread_resume(thread)

        let symbols = frames.enumerated().map { (i, addr) -> String in
            var info = Dl_info()
            if dladdr(UnsafeRawPointer(bitPattern: addr), &info) != 0 {
                let mod = info.dli_fname.map { (String(cString: $0) as NSString).lastPathComponent } ?? "?"
                let sym = info.dli_sname.map { String(cString: $0) } ?? String(format: "0x%lx", addr)
                return String(format: "  %2d %@`%@", i, mod, sym)
            }
            return String(format: "  %2d 0x%016lx", i, addr)
        }
        NSLog("[STPERF] 🔴 MAIN-THREAD HANG ~%.2fs backtrace:\n%@", elapsed, symbols.joined(separator: "\n"))
    }
}
#endif
