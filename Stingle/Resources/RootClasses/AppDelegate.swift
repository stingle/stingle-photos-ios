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
