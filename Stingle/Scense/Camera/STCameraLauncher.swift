//
//  STCameraLauncher.swift
//  Stingle
//
//  Single routing seam for every camera entry point (URL scheme, App Intent /
//  Control Center, quick action, lock-screen widget, the unlock-screen button).
//  Presents the camera full-screen over whatever is on top — including the
//  app-lock screen — without unlocking, since capture only needs the public key.
//

import UIKit
import StingleRoot

enum STCameraLaunchSurface {
    case urlScheme
    case appIntent
    case quickAction
    case controlCenter
    case lockWidget
    case unlockScreenButton
    case tab
}

final class STCameraLauncher {

    static let shared = STCameraLauncher()

    private init() {}

    private var pendingSurface: STCameraLaunchSurface?
    private(set) var isPresenting = false

    /// True while a camera launch has been requested but not yet shown. The unlock
    /// screen consults this to suppress its automatic biometric prompt, which would
    /// otherwise race the camera presentation (and surface a "user interaction
    /// required" error when its Face ID sheet can't present under the camera modal).
    var hasPendingLaunch: Bool {
        return self.pendingSurface != nil || STCameraLaunch.isPending
    }

    /// Entry point for every launch surface. Records the request and tries to show
    /// it now; if the UI isn't ready yet (cold launch) it stays pending until a
    /// later drain (`presentIfPending`) fires from a fully-routed root.
    func handle(_ surface: STCameraLaunchSurface) {
        self.pendingSurface = surface
        self.presentIfPending()
    }

    /// Drains a pending or cross-process launch. Safe to call repeatedly — it only
    /// presents once the real routed root (gallery or lock screen) is on screen, and
    /// keeps the request pending otherwise so no entry point is ever silently lost.
    func presentIfPending() {
        // A cross-process request (Control Center control / Siri App Intent) signals
        // via the app-group flag; fold it into the in-process slot so both the flag
        // and the in-app surfaces share a single, idempotent drain.
        if STCameraLaunch.consumePending() {
            self.pendingSurface = self.pendingSurface ?? .appIntent
        }
        guard let surface = self.pendingSurface else { return }
        guard !self.isPresenting else {
            self.pendingSurface = nil
            return
        }
        // Only present over the real, fully-routed root — never the transient STMainVC
        // router, the login screen, or a not-yet-interactive scene. Otherwise keep the
        // request pending; a later drain (scene activation, the lock/gallery screen
        // appearing) retries at the correct moment.
        guard STApplication.shared.utils.isLogedIn(), let top = self.readyTopMostViewController() else {
            return
        }
        self.pendingSurface = nil
        self.presentCamera(surface: surface, over: top)
    }

    // MARK: - Presentation

    private func presentCamera(surface: STCameraLaunchSurface, over top: UIViewController) {
        // Don't stack a second camera.
        if top is STCameraVC || top.children.contains(where: { $0 is STCameraVC }) { return }

        let camera = STCameraVC()
        camera.modalPresentationStyle = .fullScreen
        camera.onClose = { [weak camera, weak self] in
            self?.isPresenting = false
            camera?.dismiss(animated: true)
        }
        self.isPresenting = true
        top.present(camera, animated: true)
    }

    /// The deepest presented controller of the active scene, but only once it's
    /// genuinely presentable: the scene is foreground-active, the root view is in the
    /// window hierarchy, and the root is past the transient `STMainVC` bootstrap
    /// router. Returns nil (→ stay pending and retry) until then.
    private func readyTopMostViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) else {
            return nil
        }
        guard let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first(where: { !$0.isHidden }),
              var top = window.rootViewController,
              top.viewIfLoaded?.window != nil else {
            return nil
        }
        // STMainVC is the bootstrap router that immediately swaps the window root to
        // the gallery or the lock screen — presenting over it would be torn down.
        if top is STMainVC { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
