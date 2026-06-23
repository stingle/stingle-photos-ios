//
//  STCameraDeviceDiscovery.swift
//  StingleRoot
//
//  Wraps AVCaptureDevice.DiscoverySession: device selection, lens enumeration,
//  and capability probing so the UI can hide unsupported modes.
//

import AVFoundation
import UIKit

public struct STCameraDeviceDiscovery {

    /// Preferred device for a position: the richest virtual device available so we
    /// can switch lenses (ultra-wide / wide / tele) within a single session input.
    public static func preferredDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let backTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera
        ]
        let frontTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTrueDepthCamera,
            .builtInWideAngleCamera
        ]
        let types = position == .front ? frontTypes : backTypes
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: position)
        return session.devices.first ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    /// A device suitable for portrait/depth capture at the given position, if any.
    public static func portraitDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let types: [AVCaptureDevice.DeviceType] = position == .front
            ? [.builtInTrueDepthCamera]
            : [.builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera]
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: position)
        return session.devices.first
    }

    /// Computes the full capability set for a device once it's selected.
    public static func capability(for device: AVCaptureDevice, position: AVCaptureDevice.Position) -> STCameraCapability {
        var capability = STCameraCapability()
        capability.supportsFlash = device.hasFlash
        capability.supportsTorch = device.hasTorch

        // Portrait/depth: a depth-capable device on this position.
        capability.supportsPortrait = self.portraitDevice(for: position) != nil

        // Slow-mo: any format whose supported frame-rate range tops 120fps.
        var maxFPS: Double = 0
        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {
                maxFPS = max(maxFPS, range.maxFrameRate)
            }
        }
        capability.maxSlowMoFPS = maxFPS
        capability.supportsSlowMo = maxFPS >= 120

        // Lenses derived from the virtual device's constituents (if any).
        capability.lenses = self.lenses(for: device)
        capability.minZoom = device.minAvailableVideoZoomFactor
        capability.maxZoom = min(device.maxAvailableVideoZoomFactor, 10)
        return capability
    }

    /// Builds the user-facing lens list. For a virtual device the constituent
    /// switch-over zoom factors map to display multipliers (0.5x / 1x / 2x...).
    public static func lenses(for device: AVCaptureDevice) -> [STLens] {
        let constituents = device.constituentDevices
        guard !constituents.isEmpty else {
            return [STLens(deviceType: device.deviceType, displayZoom: 1, zoomFactor: 1)]
        }

        // The switch-over factors tell us where each constituent kicks in.
        let switchFactors = device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat(truncating: $0) }
        var lenses: [STLens] = []

        // Base (widest) lens maps to either 0.5x (ultra-wide present) or 1x.
        let hasUltraWide = constituents.contains { $0.deviceType == .builtInUltraWideCamera }
        var baseDisplay: CGFloat = hasUltraWide ? 0.5 : 1
        lenses.append(STLens(deviceType: constituents.first!.deviceType, displayZoom: baseDisplay, zoomFactor: 1))

        for (index, factor) in switchFactors.enumerated() {
            let nextIndex = index + 1
            guard nextIndex < constituents.count else { break }
            // Display multiplier relative to the 1x wide lens.
            let display = hasUltraWide ? factor * 0.5 : factor
            baseDisplay = display
            lenses.append(STLens(deviceType: constituents[nextIndex].deviceType,
                                 displayZoom: (display * 10).rounded() / 10,
                                 zoomFactor: factor))
        }
        return lenses
    }

    /// Picks the highest-fps format at-or-below a target fps for slow-motion.
    public static func bestSlowMoFormat(for device: AVCaptureDevice, targetFPS: Double, resolution: STVideoResolution) -> (format: AVCaptureDevice.Format, fps: Double)? {
        var best: (AVCaptureDevice.Format, Double)?
        let wanted = resolution.dimensions
        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            // Prefer formats that match the requested resolution; fall back to any.
            let matchesResolution = dims.width == wanted.width && dims.height == wanted.height
            for range in format.videoSupportedFrameRateRanges where range.maxFrameRate >= 120 {
                let fps = min(range.maxFrameRate, targetFPS)
                if let current = best {
                    let currentMatches = CMVideoFormatDescriptionGetDimensions(current.0.formatDescription)
                    let currentMatchesResolution = currentMatches.width == wanted.width && currentMatches.height == wanted.height
                    if (matchesResolution && !currentMatchesResolution) || fps > current.1 {
                        best = (format, fps)
                    }
                } else {
                    best = (format, fps)
                }
            }
        }
        return best.map { ($0.0, $0.1) }
    }
}
