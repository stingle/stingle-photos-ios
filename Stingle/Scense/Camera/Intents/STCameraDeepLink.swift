//
//  STCameraDeepLink.swift
//  Stingle
//
//  Single source of truth for the camera deep link + the cross-process
//  "open the camera" signal. Compiled into both the app and the widget
//  extension, so it must not reference app-only types.
//

import Foundation
import StingleRoot

enum STCameraLaunch {

    static let scheme = "stingle"
    static let host = "camera"

    static var url: URL { URL(string: "\(scheme)://\(host)")! }

    static func isCameraURL(_ url: URL) -> Bool {
        return url.scheme == scheme && url.host == host
    }

    // MARK: - Cross-process pending flag (set by the Control Center intent)

    private static let pendingKey = "camera.pendingLaunch"

    private static var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: STEnvironment.current.groupAppFileSharingBundleId)
    }

    static func setPending() {
        self.groupDefaults?.set(true, forKey: self.pendingKey)
    }

    /// Non-consuming peek at the pending flag (lets the unlock screen suppress its
    /// biometric prompt while a cross-process camera launch is still in flight).
    static var isPending: Bool {
        return self.groupDefaults?.bool(forKey: self.pendingKey) == true
    }

    /// Returns true (once) if a pending camera launch was requested, clearing it.
    static func consumePending() -> Bool {
        guard self.groupDefaults?.bool(forKey: self.pendingKey) == true else { return false }
        self.groupDefaults?.set(false, forKey: self.pendingKey)
        return true
    }
}
