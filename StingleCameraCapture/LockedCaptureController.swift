//
//  LockedCaptureController.swift
//  StingleCameraCapture
//
//  Drives STCameraEngine inside the iOS 18 locked-capture extension and routes
//  captures straight into the encrypted import pipeline — both reused verbatim
//  from StingleRoot. Works while the device is locked: encryption seals to the
//  on-disk public key.
//

import SwiftUI
import AVFoundation
import StingleRoot

@available(iOS 18.0, *)
final class LockedCaptureController: NSObject, ObservableObject {

    let engine = STCameraEngine()

    @Published var isRecording = false
    @Published var availableModes: [STCameraMode] = [.photo, .video]
    @Published var mode: STCameraMode = .photo
    @Published var lastThumbnail: UIImage?

    override init() {
        super.init()
        self.engine.delegate = self
    }

    func start() {
        self.engine.requestAuthorization { [weak self] camera, _ in
            guard let self, camera else { return }
            let settings = STAppSettings.current.camera
            self.engine.videoResolution = settings.videoResolution
            self.engine.preferHEVC = settings.videoCodecHEVC
            self.engine.mirrorFrontCamera = settings.mirrorFrontCamera
            self.engine.configure(initialMode: .photo, position: .back)
            self.engine.start()
        }
    }

    func stop() { self.engine.stop() }

    func setMode(_ mode: STCameraMode) {
        self.mode = mode
        self.engine.setMode(mode)
    }

    func switchPosition() { self.engine.switchPosition() }

    func shutter() {
        switch self.mode {
        case .photo, .portrait:
            self.engine.capturePhoto()
        case .video, .slowmo:
            if self.engine.isRecording {
                self.engine.stopRecording()
                self.isRecording = false
            } else {
                self.engine.startRecording()
                self.isRecording = true
            }
        case .timelapse:
            if self.engine.isTimeLapsing {
                self.engine.stopTimeLapse()
                self.isRecording = false
            } else {
                self.engine.startTimeLapse()
                self.isRecording = true
            }
        }
    }
}

@available(iOS 18.0, *)
extension LockedCaptureController: STCameraEngineDelegate {

    func cameraEngine(_ engine: STCameraEngine, didCapture result: STCaptureResult) {
        self.lastThumbnail = UIImage(data: result.thumbnailData)
        // Encrypt + queue for upload, exactly like the in-app camera.
        STCameraImporter.shared.import(result: result)
    }

    func cameraEngine(_ engine: STCameraEngine, didFail error: STCameraError) {
        self.isRecording = false
    }

    func cameraEngine(_ engine: STCameraEngine, didUpdateCapability capability: STCameraCapability) {
        DispatchQueue.main.async {
            self.availableModes = capability.availableModes
        }
    }
}
