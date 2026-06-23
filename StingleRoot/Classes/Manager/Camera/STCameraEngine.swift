//
//  STCameraEngine.swift
//  StingleRoot
//
//  AVFoundation capture controller for the native Stingle camera. UI-free so it
//  can be reused by the in-app camera, the over-app-lock presentation, and the
//  iOS 18 LockedCameraCapture extension. All session mutation happens on a
//  private serial queue; delegate callbacks are marshalled to `responseQueue`.
//

import AVFoundation
import CoreLocation
import UIKit

public protocol STCameraEngineDelegate: AnyObject {
    func cameraEngine(_ engine: STCameraEngine, didCapture result: STCaptureResult)
    func cameraEngine(_ engine: STCameraEngine, didFail error: STCameraError)
    func cameraEngine(_ engine: STCameraEngine, didUpdateRecordingTime seconds: TimeInterval)
    func cameraEngine(_ engine: STCameraEngine, didUpdateCapability capability: STCameraCapability)
    func cameraEngine(_ engine: STCameraEngine, didChangeInterruption isInterrupted: Bool)
    /// Lenses available on the *currently active* device (changes with mode/position),
    /// plus the active device's current zoom factor.
    func cameraEngine(_ engine: STCameraEngine, didUpdateLenses lenses: [STLens], currentZoomFactor: CGFloat)
}

public extension STCameraEngineDelegate {
    func cameraEngine(_ engine: STCameraEngine, didUpdateRecordingTime seconds: TimeInterval) {}
    func cameraEngine(_ engine: STCameraEngine, didUpdateCapability capability: STCameraCapability) {}
    func cameraEngine(_ engine: STCameraEngine, didChangeInterruption isInterrupted: Bool) {}
    func cameraEngine(_ engine: STCameraEngine, didUpdateLenses lenses: [STLens], currentZoomFactor: CGFloat) {}
}

public final class STCameraEngine: NSObject {

    public weak var delegate: STCameraEngineDelegate?

    public private(set) var mode: STCameraMode = .photo
    public private(set) var position: STCameraPosition = .back
    public private(set) var flashMode: STCameraFlashMode = .auto
    public private(set) var capability = STCameraCapability()

    // Tunables the view model populates from STAppSettings.camera.
    public var videoResolution: STVideoResolution = .hd1080
    public var preferHEVC: Bool = true
    public var videoFrameRate: Int = 30
    public var slowMoFPS: Int = 120
    public var timeLapseInterval: TimeInterval = 1.0
    public var mirrorFrontCamera: Bool = true
    /// Set by the view model only when geotagging is enabled; otherwise nil.
    public var currentLocation: CLLocation?

    public var captureSession: AVCaptureSession { self.session }

    let session = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "org.stingle.camera.session")
    let responseQueue: DispatchQueue

    var videoDeviceInput: AVCaptureDeviceInput?
    var audioDeviceInput: AVCaptureDeviceInput?
    let photoOutput = AVCapturePhotoOutput()
    let movieOutput = AVCaptureMovieFileOutput()
    let timeLapseDataOutput = AVCaptureVideoDataOutput()
    let timeLapseQueue = DispatchQueue(label: "org.stingle.camera.timelapse")

    var isConfigured = false
    var photoProcessors = Set<STPhotoCaptureProcessor>()
    var movieCaptureLocation: CLLocation?
    var recordingTimer: Timer?
    var recordingStart: Date?

    // Time-lapse state (used by +TimeLapse).
    var timeLapseAssembler: STTimeLapseAssembler?
    var lastTimeLapseSampleTime: CFTimeInterval = 0

    public init(responseQueue: DispatchQueue = .main) {
        self.responseQueue = responseQueue
        super.init()
    }

    // MARK: - Authorization

    /// Requests camera and microphone access. `completion(camera, microphone)`.
    public func requestAuthorization(_ completion: @escaping (_ camera: Bool, _ microphone: Bool) -> Void) {
        func askMic(cameraGranted: Bool) {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                self.dispatch { completion(cameraGranted, true) }
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { micGranted in
                    self.dispatch { completion(cameraGranted, micGranted) }
                }
            default:
                self.dispatch { completion(cameraGranted, false) }
            }
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            askMic(cameraGranted: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                askMic(cameraGranted: granted)
            }
        default:
            self.dispatch { completion(false, false) }
        }
    }

    // MARK: - Lifecycle

    public func configure(initialMode: STCameraMode = .photo, position: STCameraPosition = .back) {
        self.sessionQueue.async {
            self.mode = initialMode
            self.position = position
            self.configureSession()
        }
    }

    public func start() {
        self.sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.registerNotifications()
            self.session.startRunning()
        }
    }

    public func stop() {
        self.sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            self.unregisterNotifications()
        }
    }

    // MARK: - Session configuration

    private func configureSession() {
        self.session.beginConfiguration()
        defer { self.session.commitConfiguration() }

        self.session.sessionPreset = self.mode.capturesMovie ? self.videoResolution.sessionPreset : .photo

        guard self.configureVideoInput(position: self.position) else {
            self.fail(.noCaptureDevice)
            return
        }
        self.configureAudioInputIfNeeded()
        self.configureOutputs()
        self.isConfigured = true

        if let device = self.videoDeviceInput?.device {
            let capability = STCameraDeviceDiscovery.capability(for: device, position: self.position.avPosition)
            self.capability = capability
            self.dispatch { self.delegate?.cameraEngine(self, didUpdateCapability: capability) }
        }
        self.applyModeConfiguration()
        self.applyDefaultZoom()
        self.notifyActiveDeviceState()
    }

    @discardableResult
    private func configureVideoInput(position: STCameraPosition) -> Bool {
        if let existing = self.videoDeviceInput {
            self.session.removeInput(existing)
            self.videoDeviceInput = nil
        }

        // Always use the rich wide virtual device (triple/dual-wide/dual/wide) so
        // framing is identical across modes. Portrait just enables depth delivery
        // on this device — switching to a tele-based "portrait device" made the
        // preview jump to a fully-zoomed-in field of view.
        let device = STCameraDeviceDiscovery.preferredDevice(for: position.avPosition)

        guard let device, let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) else {
            return false
        }
        self.session.addInput(input)
        self.videoDeviceInput = input
        return true
    }

    private func configureAudioInputIfNeeded() {
        // Audio is only needed for video/slow-mo. Time-lapse has no audio track.
        guard self.mode == .video || self.mode == .slowmo else {
            if let audio = self.audioDeviceInput {
                self.session.removeInput(audio)
                self.audioDeviceInput = nil
            }
            return
        }
        guard self.audioDeviceInput == nil,
              let mic = AVCaptureDevice.default(for: .audio),
              let input = try? AVCaptureDeviceInput(device: mic),
              self.session.canAddInput(input) else { return }
        self.session.addInput(input)
        self.audioDeviceInput = input
    }

    private func configureOutputs() {
        if self.session.canAddOutput(self.photoOutput), !self.session.outputs.contains(self.photoOutput) {
            self.session.addOutput(self.photoOutput)
        }
        self.photoOutput.maxPhotoQualityPrioritization = .balanced

        if self.session.canAddOutput(self.movieOutput), !self.session.outputs.contains(self.movieOutput) {
            self.session.addOutput(self.movieOutput)
        }

        self.timeLapseDataOutput.setSampleBufferDelegate(self, queue: self.timeLapseQueue)
        self.timeLapseDataOutput.alwaysDiscardsLateVideoFrames = true
        self.timeLapseDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if self.session.canAddOutput(self.timeLapseDataOutput), !self.session.outputs.contains(self.timeLapseDataOutput) {
            self.session.addOutput(self.timeLapseDataOutput)
        }
    }

    /// Per-mode tweaks applied after inputs/outputs exist (depth, fps, stabilization).
    func applyModeConfiguration() {
        guard let device = self.videoDeviceInput?.device else { return }

        // Depth/portrait delivery.
        let wantsDepth = (self.mode == .portrait) && self.photoOutput.isDepthDataDeliverySupported
        self.photoOutput.isDepthDataDeliveryEnabled = wantsDepth
        if self.photoOutput.isPortraitEffectsMatteDeliverySupported {
            self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = wantsDepth
        }

        // Slow-mo: lock to a high-fps format.
        if self.mode == .slowmo,
           let best = STCameraDeviceDiscovery.bestSlowMoFormat(for: device, targetFPS: Double(self.slowMoFPS), resolution: self.videoResolution) {
            self.configureFrameRate(device: device, format: best.format, fps: best.fps)
        } else if self.mode == .video {
            self.configureFrameRate(device: device, format: nil, fps: Double(self.videoFrameRate))
        }

        // Video stabilization for movie connections.
        if let connection = self.movieOutput.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
    }

    private func configureFrameRate(device: AVCaptureDevice, format: AVCaptureDevice.Format?, fps: Double) {
        do {
            try device.lockForConfiguration()
            if let format { device.activeFormat = format }
            let duration = CMTimeMake(value: 1, timescale: Int32(fps))
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
        } catch {
            // Non-fatal: fall back to the format's default frame rate.
        }
    }

    /// Opens at the natural "1×" (wide) lens rather than the device's raw zoom
    /// factor of 1.0, which on multi-lens devices is the ultra-wide (0.5×). For
    /// single-lens portrait devices this resolves to that lens's widest framing.
    func applyDefaultZoom() {
        guard let device = self.videoDeviceInput?.device else { return }
        let lenses = STCameraDeviceDiscovery.lenses(for: device)
        let oneX = lenses.min(by: { abs($0.displayZoom - 1) < abs($1.displayZoom - 1) })
        let factor = oneX?.zoomFactor ?? device.minAvailableVideoZoomFactor
        let clamped = max(device.minAvailableVideoZoomFactor, min(factor, device.maxAvailableVideoZoomFactor))
        try? device.lockForConfiguration()
        device.videoZoomFactor = clamped
        device.unlockForConfiguration()
    }

    /// Reports the active device's lenses + current zoom to the delegate so the UI
    /// can present preset lens buttons that match the real hardware.
    func notifyActiveDeviceState() {
        guard let device = self.videoDeviceInput?.device else { return }
        let lenses = STCameraDeviceDiscovery.lenses(for: device)
        let zoom = device.videoZoomFactor
        self.dispatch { self.delegate?.cameraEngine(self, didUpdateLenses: lenses, currentZoomFactor: zoom) }
    }

    // MARK: - Mode & camera switching

    public func setMode(_ mode: STCameraMode, completion: (() -> Void)? = nil) {
        self.sessionQueue.async {
            guard mode != self.mode else {
                self.dispatch { completion?() }
                return
            }
            guard self.capability.availableModes.contains(mode) else {
                self.fail(.modeNotSupported(mode))
                self.dispatch { completion?() }
                return
            }
            self.session.beginConfiguration()
            self.mode = mode
            self.session.sessionPreset = mode.capturesMovie ? self.videoResolution.sessionPreset : .photo
            // Portrait may need a different device than the wide virtual device.
            self.configureVideoInput(position: self.position)
            self.configureAudioInputIfNeeded()
            self.session.commitConfiguration()
            self.applyModeConfiguration()
            self.applyDefaultZoom()
            self.notifyActiveDeviceState()
            self.dispatch { completion?() }
        }
    }

    public func switchPosition() {
        self.sessionQueue.async {
            let new = self.position.toggled
            self.session.beginConfiguration()
            self.position = new
            self.configureVideoInput(position: new)
            self.session.commitConfiguration()
            self.applyModeConfiguration()
            if let device = self.videoDeviceInput?.device {
                let capability = STCameraDeviceDiscovery.capability(for: device, position: new.avPosition)
                self.capability = capability
                self.dispatch { self.delegate?.cameraEngine(self, didUpdateCapability: capability) }
            }
            self.applyDefaultZoom()
            self.notifyActiveDeviceState()
        }
    }

    // MARK: - Controls

    public func setFlash(_ flash: STCameraFlashMode) {
        self.flashMode = flash
    }

    public func setTorch(on: Bool) {
        self.sessionQueue.async {
            guard let device = self.videoDeviceInput?.device, device.hasTorch else { return }
            try? device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }
    }

    public func setZoom(_ factor: CGFloat, ramp: Bool = false) {
        self.sessionQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, device.maxAvailableVideoZoomFactor))
            try? device.lockForConfiguration()
            if ramp {
                device.ramp(toVideoZoomFactor: clamped, withRate: 4)
            } else {
                device.videoZoomFactor = clamped
            }
            device.unlockForConfiguration()
        }
    }

    public func selectLens(_ lens: STLens) {
        self.setZoom(lens.zoomFactor, ramp: true)
    }

    public func focusAndExpose(atDevicePoint point: CGPoint, monitorSubjectAreaChange: Bool = true) {
        self.sessionQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {}
        }
    }

    public func setExposureBias(_ bias: Float) {
        self.sessionQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            let clamped = max(device.minExposureTargetBias, min(bias, device.maxExposureTargetBias))
            try? device.lockForConfiguration()
            device.setExposureTargetBias(clamped, completionHandler: nil)
            device.unlockForConfiguration()
        }
    }

    // MARK: - Helpers shared with mode extensions

    func dispatch(_ block: @escaping () -> Void) {
        self.responseQueue.async(execute: block)
    }

    func fail(_ error: STCameraError) {
        self.dispatch { self.delegate?.cameraEngine(self, didFail: error) }
    }

    /// A fresh plaintext temp file URL for a capture, under a per-capture folder.
    func makeTempURL(extension ext: String) -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("camera-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("\(UUID().uuidString).\(ext)")
    }

    func videoRotationAngle(for connection: AVCaptureConnection) {
        // Keep the capture upright following the device. iOS 17+ uses
        // videoRotationAngle; older systems fall back to videoOrientation.
        if #available(iOS 17.0, *) {
            let angle: CGFloat
            switch UIDevice.current.orientation {
            case .landscapeLeft: angle = 0
            case .landscapeRight: angle = 180
            case .portraitUpsideDown: angle = 270
            default: angle = 90
            }
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    // MARK: - Interruptions

    private func registerNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.sessionWasInterrupted(_:)), name: .AVCaptureSessionWasInterrupted, object: self.session)
        center.addObserver(self, selector: #selector(self.sessionInterruptionEnded(_:)), name: .AVCaptureSessionInterruptionEnded, object: self.session)
        center.addObserver(self, selector: #selector(self.sessionRuntimeError(_:)), name: .AVCaptureSessionRuntimeError, object: self.session)
    }

    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionWasInterrupted, object: self.session)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionInterruptionEnded, object: self.session)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionRuntimeError, object: self.session)
    }

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        self.dispatch { self.delegate?.cameraEngine(self, didChangeInterruption: true) }
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        self.dispatch { self.delegate?.cameraEngine(self, didChangeInterruption: false) }
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        // Try to recover media-services-reset by restarting on the session queue.
        if error.code == .mediaServicesWereReset {
            self.sessionQueue.async {
                if self.isConfigured { self.session.startRunning() }
            }
        } else {
            self.fail(.captureFailed(underlying: error))
        }
    }

    deinit {
        self.unregisterNotifications()
    }
}
