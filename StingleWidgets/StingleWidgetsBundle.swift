//
//  StingleWidgetsBundle.swift
//  StingleWidgets
//
//  Bundles the Stingle widgets and controls. The Control Center camera control
//  is iOS 18+; the Lock Screen camera widget is iOS 16+.
//

import SwiftUI
import WidgetKit

@main
struct StingleWidgetsBundle: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        CameraLockScreenWidget()
        if #available(iOS 18.0, *) {
            CameraControlWidget()
        }
    }
}
