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
        
        DispatchQueue.main.async {
            STBGTaskScheduler.shared.start()
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
