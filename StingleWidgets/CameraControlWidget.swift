//
//  CameraControlWidget.swift
//  StingleWidgets
//
//  iOS 18 Control Center control — the closest thing to a dedicated "Stingle
//  Camera" launcher icon. One tap opens the camera (capture works while the app
//  is locked).
//

import SwiftUI
import WidgetKit
import AppIntents

@available(iOS 18.0, *)
struct CameraControlWidget: ControlWidget {

    static let kind = "org.stingle.photos.control.camera"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenCameraIntent()) {
                Label("Stingle Camera", systemImage: "camera.fill")
            }
        }
        .displayName("Stingle Camera")
        .description("Capture encrypted photos and videos.")
    }
}
