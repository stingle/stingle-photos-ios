//
//  StingleCameraCaptureExtension.swift
//  StingleCameraCapture
//
//  iOS 18 LockedCameraCapture extension entry point. Lets users capture into
//  Stingle's encrypted store directly from the device lock screen.
//

import LockedCameraCapture
import SwiftUI

@available(iOS 18.0, *)
@main
struct StingleCameraCaptureExtension: LockedCameraCaptureExtension {

    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            LockedCaptureView(session: session)
        }
    }
}
