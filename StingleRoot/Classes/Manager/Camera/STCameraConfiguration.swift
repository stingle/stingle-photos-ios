//
//  STCameraConfiguration.swift
//  StingleRoot
//
//  Value types shared by the native camera engine. UI-free, iOS 16 floor.
//

import AVFoundation
import CoreLocation
import UIKit

public enum STCameraMode: Int, CaseIterable, Codable {
    case photo
    case video
    case slowmo
    case timelapse
    case portrait

    public var isVideoLike: Bool {
        switch self {
        case .photo, .portrait:
            return false
        case .video, .slowmo, .timelapse:
            return true
        }
    }

    /// Modes that record continuously and produce a single movie file.
    public var capturesMovie: Bool {
        switch self {
        case .video, .slowmo:
            return true
        case .photo, .portrait, .timelapse:
            return false
        }
    }
}

public enum STCameraPosition {
    case back
    case front

    public var avPosition: AVCaptureDevice.Position {
        switch self {
        case .back: return .back
        case .front: return .front
        }
    }

    public var toggled: STCameraPosition {
        return self == .back ? .front : .back
    }
}

public enum STCameraFlashMode: Int, CaseIterable {
    case off
    case on
    case auto

    public var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

public enum STVideoResolution: Int, CaseIterable, Codable {
    case hd720
    case hd1080
    case uhd4k

    public var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .hd720: return .hd1280x720
        case .hd1080: return .hd1920x1080
        case .uhd4k: return .hd4K3840x2160
        }
    }

    public var dimensions: CMVideoDimensions {
        switch self {
        case .hd720: return CMVideoDimensions(width: 1280, height: 720)
        case .hd1080: return CMVideoDimensions(width: 1920, height: 1080)
        case .uhd4k: return CMVideoDimensions(width: 3840, height: 2160)
        }
    }
}

/// A single selectable lens (e.g. 0.5x ultra-wide, 1x wide, 2x tele).
public struct STLens: Equatable {
    public let deviceType: AVCaptureDevice.DeviceType
    public let displayZoom: CGFloat       // user-facing multiplier, e.g. 0.5, 1, 2
    public let zoomFactor: CGFloat        // videoZoomFactor on the active virtual device

    public init(deviceType: AVCaptureDevice.DeviceType, displayZoom: CGFloat, zoomFactor: CGFloat) {
        self.deviceType = deviceType
        self.displayZoom = displayZoom
        self.zoomFactor = zoomFactor
    }
}

/// The result of a single capture, ready to hand to `STCameraImporter`.
public struct STCaptureResult {
    public let fileURL: URL                 // plaintext temp file (caller/importer must delete after use)
    public let fileType: STHeader.FileType
    public let thumbnailData: Data          // engine-generated, never a library read
    public let duration: TimeInterval
    public let creationDate: Date
    public let location: CLLocation?

    public init(fileURL: URL, fileType: STHeader.FileType, thumbnailData: Data, duration: TimeInterval, creationDate: Date, location: CLLocation?) {
        self.fileURL = fileURL
        self.fileType = fileType
        self.thumbnailData = thumbnailData
        self.duration = duration
        self.creationDate = creationDate
        self.location = location
    }
}

/// Device-gated feature probe computed once per (device, position).
public struct STCameraCapability {
    public var supportsFlash: Bool = false
    public var supportsTorch: Bool = false
    public var supportsPortrait: Bool = false      // depth/portrait-effects-matte capable
    public var supportsSlowMo: Bool = false        // a high-fps format exists
    public var maxSlowMoFPS: Double = 0
    public var lenses: [STLens] = []
    public var minZoom: CGFloat = 1
    public var maxZoom: CGFloat = 1

    public var availableModes: [STCameraMode] {
        // Only Photo + Video for now. The engine still supports the others —
        // re-enable by appending them here:
        //   if supportsSlowMo { modes.append(.slowmo) }
        //   modes.append(.timelapse)
        //   if supportsPortrait { modes.append(.portrait) }
        let modes: [STCameraMode] = [.photo, .video]
        return modes.sorted { $0.rawValue < $1.rawValue }
    }
}

public enum STCameraError: Error {
    case notAuthorized
    case microphoneNotAuthorized
    case configurationFailed
    case noCaptureDevice
    case captureFailed(underlying: Error?)
    case modeNotSupported(STCameraMode)
    case interrupted

    public var localizedDescription: String {
        switch self {
        case .notAuthorized: return "camera_not_authorized".localized
        case .microphoneNotAuthorized: return "microphone_not_authorized".localized
        case .configurationFailed: return "camera_configuration_failed".localized
        case .noCaptureDevice: return "camera_no_device".localized
        case .captureFailed: return "camera_capture_failed".localized
        case .modeNotSupported: return "camera_mode_not_supported".localized
        case .interrupted: return "camera_interrupted".localized
        }
    }
}
