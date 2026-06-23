//
//  STCameraEngine+Video.swift
//  StingleRoot
//
//  Video and slow-motion recording via AVCaptureMovieFileOutput.
//

import AVFoundation
import CoreLocation
import UIKit

extension STCameraEngine {

    public var isRecording: Bool {
        self.movieOutput.isRecording
    }

    public func startRecording() {
        self.sessionQueue.async {
            guard self.isConfigured, !self.movieOutput.isRecording else { return }
            guard self.mode == .video || self.mode == .slowmo else {
                self.fail(.modeNotSupported(self.mode))
                return
            }

            if let connection = self.movieOutput.connection(with: .video) {
                self.videoRotationAngle(for: connection)
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (self.position == .front) && self.mirrorFrontCamera
                }
            }

            // Prefer HEVC where available.
            if let connection = self.movieOutput.connection(with: .video),
               self.preferHEVC,
               self.movieOutput.availableVideoCodecTypes.contains(.hevc) {
                self.movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
            }

            self.movieCaptureLocation = self.currentLocation
            let url = self.makeTempURL(extension: "mov")
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
            self.recordingStart = Date()
            self.startRecordingTimer()
        }
    }

    public func stopRecording() {
        self.sessionQueue.async {
            guard self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
        }
    }

    private func startRecordingTimer() {
        self.dispatch {
            self.recordingTimer?.invalidate()
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                guard let self, let start = self.recordingStart else { return }
                self.delegate?.cameraEngine(self, didUpdateRecordingTime: Date().timeIntervalSince(start))
            }
        }
    }

    private func stopRecordingTimer() {
        self.dispatch {
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil
            self.recordingStart = nil
        }
    }
}

extension STCameraEngine: AVCaptureFileOutputRecordingDelegate {

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.stopRecordingTimer()

        if let error {
            // Recording may still have produced a usable partial file; treat as failure to be safe.
            try? FileManager.default.removeItem(at: outputFileURL)
            self.fail(.captureFailed(underlying: error))
            return
        }

        let asset = AVAsset(url: outputFileURL)
        let duration = asset.duration.seconds
        let thumbTime = min(duration, 0.3)
        guard let thumbnailData = try? asset.generateThumbnailFromAsset(forTime: thumbTime).thumbnailData else {
            try? FileManager.default.removeItem(at: outputFileURL)
            self.fail(.captureFailed(underlying: nil))
            return
        }

        let result = STCaptureResult(fileURL: outputFileURL,
                                     fileType: .video,
                                     thumbnailData: thumbnailData,
                                     duration: duration,
                                     creationDate: Date(),
                                     location: self.movieCaptureLocation)
        self.dispatch { self.delegate?.cameraEngine(self, didCapture: result) }
    }
}
