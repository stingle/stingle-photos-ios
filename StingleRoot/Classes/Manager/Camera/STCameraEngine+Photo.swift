//
//  STCameraEngine+Photo.swift
//  StingleRoot
//
//  Still + portrait/depth capture via AVCapturePhotoOutput.
//

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreLocation
import UIKit

extension STCameraEngine {

    public func capturePhoto() {
        self.sessionQueue.async {
            guard self.isConfigured else {
                self.fail(.configurationFailed)
                return
            }
            if let connection = self.photoOutput.connection(with: .video) {
                self.videoRotationAngle(for: connection)
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = (self.position == .front) && self.mirrorFrontCamera
                }
            }

            let settings = self.makePhotoSettings()
            let processor = STPhotoCaptureProcessor(engine: self,
                                                    isPortrait: self.mode == .portrait,
                                                    creationDate: Date(),
                                                    location: self.currentLocation) { [weak self] processor, result, error in
                guard let self else { return }
                self.sessionQueue.async { self.photoProcessors.remove(processor) }
                if let result {
                    self.dispatch { self.delegate?.cameraEngine(self, didCapture: result) }
                } else {
                    self.fail(.captureFailed(underlying: error))
                }
            }
            self.photoProcessors.insert(processor)
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }

    private func makePhotoSettings() -> AVCapturePhotoSettings {
        let settings: AVCapturePhotoSettings
        if self.preferHEVC, self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        if let device = self.videoDeviceInput?.device, device.hasFlash {
            settings.flashMode = self.flashMode.avFlashMode
        }
        // .balanced keeps shutter latency low; .quality triggers Deep Fusion /
        // computational stacking which adds a noticeable delay before capture.
        settings.photoQualityPrioritization = .balanced
        if self.mode == .portrait {
            settings.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliveryEnabled
            settings.embedsDepthDataInPhoto = settings.isDepthDataDeliveryEnabled
            settings.isPortraitEffectsMatteDeliveryEnabled = self.photoOutput.isPortraitEffectsMatteDeliveryEnabled
        }
        return settings
    }
}

/// Per-capture delegate, kept alive by the engine until processing completes.
final class STPhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {

    typealias Completion = (_ processor: STPhotoCaptureProcessor, _ result: STCaptureResult?, _ error: Error?) -> Void

    private weak var engine: STCameraEngine?
    private let isPortrait: Bool
    private let creationDate: Date
    private let location: CLLocation?
    private let completion: Completion

    init(engine: STCameraEngine, isPortrait: Bool, creationDate: Date, location: CLLocation?, completion: @escaping Completion) {
        self.engine = engine
        self.isPortrait = isPortrait
        self.creationDate = creationDate
        self.location = location
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            self.completion(self, nil, error)
            return
        }
        guard let engine = self.engine,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            self.completion(self, nil, STCameraError.captureFailed(underlying: error))
            return
        }

        // Portrait: bake a depth/matte-based background blur. AVFoundation only
        // hands us the photo + matte — it does NOT apply the bokeh itself, so we
        // composite it here. Falls back to the plain photo if no matte arrived.
        var outputData = data
        var ext = (engine.preferHEVC && output.availablePhotoCodecTypes.contains(.hevc)) ? "heic" : "jpg"
        if self.isPortrait, let blurred = Self.renderPortrait(photo: photo, baseImage: data) {
            outputData = blurred
            ext = "jpg"
        }

        let url = engine.makeTempURL(extension: ext)
        do {
            try outputData.write(to: url)
        } catch {
            self.completion(self, nil, error)
            return
        }

        let thumbSource = (outputData == data) ? image : UIImage(data: outputData) ?? image
        guard let thumbnailData = thumbSource.thumbnailData else {
            self.completion(self, nil, STCameraError.captureFailed(underlying: nil))
            return
        }

        let result = STCaptureResult(fileURL: url,
                                     fileType: .image,
                                     thumbnailData: thumbnailData,
                                     duration: .zero,
                                     creationDate: self.creationDate,
                                     location: self.location)
        self.completion(self, result, nil)
    }

    /// Composites a portrait blur using the portrait-effects matte (preferred) or
    /// the depth map. Returns nil if neither is available.
    private static func renderPortrait(photo: AVCapturePhoto, baseImage data: Data) -> Data? {
        let orientation = CGImagePropertyOrientation(rawValue: (photo.metadata[kCGImagePropertyOrientation as String] as? UInt32) ?? 1) ?? .up

        guard var input = CIImage(data: data) else { return nil }
        input = input.oriented(orientation)

        // Build a foreground mask (1 = subject, 0 = background).
        var mask: CIImage?
        if let matte = photo.portraitEffectsMatte?.applyingExifOrientation(orientation) {
            mask = CIImage(cvImageBuffer: matte.mattingImage)
        } else if let depth = (photo.depthData?.applyingExifOrientation(orientation))?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32) {
            // Normalize disparity into a 0…1 foreground mask.
            let disparity = CIImage(cvImageBuffer: depth.depthDataMap)
            mask = disparity.applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: 4.0])
        }
        guard var maskImage = mask else { return nil }

        // Scale the mask to the full-resolution image.
        let sx = input.extent.width / maskImage.extent.width
        let sy = input.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        let blurred = input.clampedToExtent()
            .applyingGaussianBlur(sigma: 14)
            .cropped(to: input.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = input          // sharp subject where mask = 1
        blend.backgroundImage = blurred   // blurred where mask = 0
        blend.maskImage = maskImage
        guard let composited = blend.outputImage else { return nil }

        let context = CIContext()
        guard let cg = context.createCGImage(composited, from: input.extent) else { return nil }
        return UIImage(cgImage: cg).jpegData(compressionQuality: 0.95)
    }
}
