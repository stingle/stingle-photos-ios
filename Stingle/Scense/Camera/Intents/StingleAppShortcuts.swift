//
//  StingleAppShortcuts.swift
//  Stingle
//
//  Exposes OpenCameraIntent to Siri and Spotlight as an App Shortcut so users
//  can say "Open Stingle Camera".
//

import AppIntents

@available(iOS 16.0, *)
struct StingleAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCameraIntent(),
            phrases: [
                "Open \(.applicationName) Camera",
                "Take a photo with \(.applicationName)",
                "\(.applicationName) Camera"
            ],
            shortTitle: "Camera",
            systemImageName: "camera.fill"
        )
    }
}
