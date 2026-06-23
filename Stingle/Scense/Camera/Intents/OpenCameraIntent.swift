//
//  OpenCameraIntent.swift
//  Stingle
//
//  App Intent that opens the Stingle camera. Used by the Control Center control
//  and the Siri App Shortcut. Shared by the app and widget targets, so perform()
//  must avoid app-only types — it signals via the app-group flag and relies on
//  openAppWhenRun to bring the app forward, where SceneDelegate routes to camera.
//

import AppIntents

@available(iOS 16.0, *)
struct OpenCameraIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Stingle Camera"
    static var description = IntentDescription("Opens the Stingle camera to capture encrypted photos and videos.")

    // Bring the host app to the foreground when this intent runs.
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        STCameraLaunch.setPending()
        return .result()
    }
}
