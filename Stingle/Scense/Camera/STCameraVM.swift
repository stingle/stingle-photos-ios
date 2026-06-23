//
//  STCameraVM.swift
//  Stingle
//
//  Owns the capture engine, permissions, geotagging, and forwards captures into
//  the encrypted import pipeline.
//

import UIKit
import CoreLocation
import StingleRoot

protocol STCameraVMDelegate: AnyObject {
    func cameraVM(_ vm: STCameraVM, didUpdateCapability capability: STCameraCapability)
    func cameraVM(_ vm: STCameraVM, didCaptureThumbnail image: UIImage?)
    func cameraVM(_ vm: STCameraVM, didFail error: STCameraError)
    func cameraVM(_ vm: STCameraVM, didUpdateRecordingTime seconds: TimeInterval)
    func cameraVM(_ vm: STCameraVM, didChangeInterruption isInterrupted: Bool)
    func cameraVM(_ vm: STCameraVM, didUpdateLenses lenses: [STLens], currentZoomFactor: CGFloat)
}

final class STCameraVM: NSObject {

    weak var delegate: STCameraVMDelegate?

    let engine = STCameraEngine()
    private let locationManager = CLLocationManager()
    private var wantsLocation = false

    private(set) var lastThumbnail: UIImage?

    /// Plaintext bytes of the most recent in-session photo capture. Kept so the
    /// just-shot photo can be reviewed full-screen even while the app is locked
    /// (when the encrypted library can't be decrypted). Cleared for video.
    private(set) var lastCaptureImageData: Data?

    /// While the app-lock is engaged we capture-only: no browsing the library.
    var isAppLocked: Bool { STApplication.shared.utils.appIsLocked() }

    override init() {
        super.init()
        self.engine.delegate = self
        self.locationManager.delegate = self
    }

    var availableModes: [STCameraMode] { self.engine.capability.availableModes }
    var capability: STCameraCapability { self.engine.capability }

    // MARK: - Setup

    func applySettings() {
        let camera = STAppSettings.current.camera
        self.engine.videoResolution = camera.videoResolution
        self.engine.preferHEVC = camera.videoCodecHEVC
        self.engine.videoFrameRate = camera.videoFPS
        self.engine.slowMoFPS = camera.slowMoFPS
        self.engine.timeLapseInterval = camera.timeLapseInterval
        self.engine.mirrorFrontCamera = camera.mirrorFrontCamera
        self.wantsLocation = camera.geotaggingEnabled
        if self.wantsLocation {
            self.startLocationIfPossible()
        }
    }

    var defaultMode: STCameraMode { STAppSettings.current.camera.defaultMode }
    var gridEnabled: Bool { STAppSettings.current.camera.gridEnabled }

    func requestAuthorization(_ completion: @escaping (_ camera: Bool, _ mic: Bool) -> Void) {
        self.engine.requestAuthorization(completion)
    }

    func configure(mode: STCameraMode) {
        self.engine.configure(initialMode: mode, position: .back)
    }

    func start() { self.engine.start() }
    func stop() { self.engine.stop() }

    // MARK: - Location (geotagging, opt-in)

    private func startLocationIfPossible() {
        let status = self.locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            self.locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    // MARK: - Capture

    func capturePhoto() { self.engine.capturePhoto() }
    func startRecording() { self.engine.startRecording() }
    func stopRecording() { self.engine.stopRecording() }
    func startTimeLapse() { self.engine.startTimeLapse() }
    func stopTimeLapse() { self.engine.stopTimeLapse() }

    private func handle(result: STCaptureResult) {
        let thumb = UIImage(data: result.thumbnailData)
        self.lastThumbnail = thumb
        // Snapshot the plaintext photo bytes BEFORE import runs (import deletes the
        // temp file once encryption finishes) so we can review it while locked.
        if result.fileType == .image {
            self.lastCaptureImageData = try? Data(contentsOf: result.fileURL)
        } else {
            self.lastCaptureImageData = nil
        }
        self.delegate?.cameraVM(self, didCaptureThumbnail: thumb)
        // Encrypt + queue for upload. Works while locked: seals to the public key.
        STCameraImporter.shared.import(result: result)
    }
}

extension STCameraVM: STCameraEngineDelegate {

    func cameraEngine(_ engine: STCameraEngine, didCapture result: STCaptureResult) {
        self.handle(result: result)
    }

    func cameraEngine(_ engine: STCameraEngine, didFail error: STCameraError) {
        self.delegate?.cameraVM(self, didFail: error)
    }

    func cameraEngine(_ engine: STCameraEngine, didUpdateRecordingTime seconds: TimeInterval) {
        self.delegate?.cameraVM(self, didUpdateRecordingTime: seconds)
    }

    func cameraEngine(_ engine: STCameraEngine, didUpdateCapability capability: STCameraCapability) {
        self.delegate?.cameraVM(self, didUpdateCapability: capability)
    }

    func cameraEngine(_ engine: STCameraEngine, didChangeInterruption isInterrupted: Bool) {
        self.delegate?.cameraVM(self, didChangeInterruption: isInterrupted)
    }

    func cameraEngine(_ engine: STCameraEngine, didUpdateLenses lenses: [STLens], currentZoomFactor: CGFloat) {
        self.delegate?.cameraVM(self, didUpdateLenses: lenses, currentZoomFactor: currentZoomFactor)
    }
}

extension STCameraVM: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard self.wantsLocation else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.engine.currentLocation = locations.last
    }
}
