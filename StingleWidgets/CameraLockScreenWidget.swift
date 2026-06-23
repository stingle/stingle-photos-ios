//
//  CameraLockScreenWidget.swift
//  StingleWidgets
//
//  A Lock Screen / Home Screen accessory widget that opens straight into the
//  Stingle camera via the shared deep link.
//

import SwiftUI
import WidgetKit

struct CameraWidgetEntry: TimelineEntry {
    let date: Date
}

struct CameraWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CameraWidgetEntry { CameraWidgetEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (CameraWidgetEntry) -> Void) {
        completion(CameraWidgetEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CameraWidgetEntry>) -> Void) {
        completion(Timeline(entries: [CameraWidgetEntry(date: Date())], policy: .never))
    }
}

struct CameraLockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            switch self.family {
            case .accessoryCircular:
                Image(systemName: "camera.fill").font(.title2)
            default:
                Label("Camera", systemImage: "camera.fill").font(.headline)
            }
        }
        .widgetURL(URL(string: "stingle://camera"))
    }
}

struct CameraLockScreenWidget: Widget {

    static let kind = "org.stingle.photos.widget.camera"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: CameraWidgetProvider()) { _ in
            CameraLockScreenWidgetView()
        }
        .configurationDisplayName("Stingle Camera")
        .description("Open the Stingle camera.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
