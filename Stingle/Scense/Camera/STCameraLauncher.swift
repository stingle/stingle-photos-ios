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

    /// Warm path: present now if the UI is ready, otherwise stash for cold launch.
    func handle(_ surface: STCameraLaunchSurface) {
        if self.topMostViewController() != nil {
            self.presentCamera(surface: surface)
        } else {
            self.pendingSurface = surface
        }
    }

    /// Called once the root UI is ready (e.g. after STMainVC finishes setup) and
    /// when the scene becomes active, to consume a pending or cross-process launch.
    func presentIfPending() {
        if STCameraLaunch.consumePending() {
            self.pendingSurface = self.pendingSurface ?? .controlCenter
        }
        guard let surface = self.pendingSurface else { return }
        self.pendingSurface = nil
        self.presentCamera(surface: surface)
    }

    // MARK: - Presentation

    private func presentCamera(surface: STCameraLaunchSurface) {
        guard !self.isPresenting, let top = self.topMostViewController() else { return }
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

    private func topMostViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first,
              var top = window.rootViewController else {
            return nil
        }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
