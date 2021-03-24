//
//  AppDelegate.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/3/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static func unLock(with password: String) throws {
        
        if STApplication.shared.dataBase.userProvider.user != nil {
            let key = try STApplication.shared.crypto.getPrivateKey(password: password)
            KeyManagement.key = key
        }
        
        print("storagePath = ", STApplication.shared.fileSystem.storageURl ?? "")
        
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        try? AppDelegate.unLock(with: "xoren010")
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

    func applicationDidEnterBackground(_ application: UIApplication) {
//        SPApplication.lock()
    }

}

