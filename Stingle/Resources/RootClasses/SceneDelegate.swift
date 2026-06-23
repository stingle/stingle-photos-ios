//
//  SceneDelegate.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/3/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // Opaque blur placed over the window while the app is inactive/backgrounded so the snapshot iOS
    // captures for the app switcher (and persists to disk) never shows decrypted photos/thumbnails.
    private var privacyCoverView: UIView?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        // Cold launch via the camera deep link or the home-screen quick action:
        // stash the request; STMainVC consumes it once the root UI is ready.
        if connectionOptions.urlContexts.contains(where: { STCameraLaunch.isCameraURL($0.url) }) {
            STCameraLauncher.shared.handle(.urlScheme)
        } else if let shortcut = connectionOptions.shortcutItem, shortcut.type == Self.cameraShortcutType {
            STCameraLauncher.shared.handle(.quickAction)
        }
    }

    static let cameraShortcutType = "org.stingle.photos.shortcut.camera"

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Warm path: the app is already running.
        if URLContexts.contains(where: { STCameraLaunch.isCameraURL($0.url) }) {
            STCameraLauncher.shared.handle(.urlScheme)
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == Self.cameraShortcutType {
            STCameraLauncher.shared.handle(.quickAction)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        self.hidePrivacyCover()
        // Consume a cross-process control/intent launch once the scene is active.
        STCameraLauncher.shared.presentIfPending()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Cover the window before iOS snapshots it for the app switcher.
        self.showPrivacyCover()
    }

    private func showPrivacyCover() {
        guard let window = self.window, self.privacyCoverView == nil else {
            return
        }
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.frame = window.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(blur)
        self.privacyCoverView = blur
    }

    private func hidePrivacyCover() {
        self.privacyCoverView?.removeFromSuperview()
        self.privacyCoverView = nil
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

}

