//
//  STCameraEngine+TimeLapse.swift
//  StingleRoot
//
//  Interval frame capture assembled into a sped-up movie. Frames stream straight
//  into AVAssetWriter via STTimeLapseAssembler — never buffered in bulk.
//

import AVFoundation
import CoreLocation
import UIKit

extension STCameraEngine {

    public var isTimeLapsing: Bool {
        self.timeLapseAssembler != nil
    }

    public func startTimeLapse() {
        self.sessionQueue.async {
            guard self.isConfigured, self.timeLapseAssembler == nil else { return }
            guard self.mode == .timelapse else {
                self.fail(.modeNotSupported(self.mode))
                return
            }
            if let connection = self.timeLapseDataOutput.connection(with: .video) {
                self.videoRotationAngle(for: connection)
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (self.position == .front) && self.mirrorFrontCamera
                }
            }
            let url = self.makeTempURL(extension: "mp4")
            self.timeLapseAssembler = STTimeLapseAssembler(outputURL: url, playbackFrameRate: 30, preferHEVC: self.preferHEVC)
            self.movieCaptureLocation = self.currentLocation
            self.lastTimeLapseSampleTime = 0
            self.recordingStart = Date()
            self.startTimeLapseTimer()
        }
    }

    public func stopTimeLapse() {
        self.sessionQueue.async {
            guard let assembler = self.timeLapseAssembler else { return }
            self.timeLapseAssembler = nil
            self.dispatch {
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
            }
            let location = self.movieCaptureLocation
            assembler.finish { [weak self] success in
                guard let self else { return }
                guard success, assembler.frameCount > 0 else {
                    assembler.cancel()
                    self.fail(.captureFailed(underlying: nil))
                    return
                }
                let url = assembler.outputURL
                let asset = AVAsset(url: url)
                let duration = asset.duration.seconds
                guard let thumbnailData = try? asset.generateThumbnailFromAsset(forTime: .zero).thumbnailData else {
                    self.fail(.captureFailed(underlying: nil))
                    return
                }
                let result = STCaptureResult(fileURL: url,
                                             fileType: .video,
                                             thumbnailData: thumbnailData,
                                             duration: duration,
                                             creationDate: Date(),
                                             location: location)
                self.dispatch { self.delegate?.cameraEngine(self, didCapture: result) }
            }
        }
    }

    private func startTimeLapseTimer() {
        self.dispatch {
            self.recordingTimer?.invalidate()
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self, let start = self.recordingStart else { return }
                self.delegate?.cameraEngine(self, didUpdateRecordingTime: Date().timeIntervalSince(start))
            }
        }
    }
}

extension STCameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Only active during a time-lapse session; otherwise discarded.
        guard let assembler = self.timeLapseAssembler else { return }
        let now = CACurrentMediaTime()
        guard now - self.lastTimeLapseSampleTime >= self.timeLapseInterval else { return }
        self.lastTimeLapseSampleTime = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        assembler.append(pixelBuffer: pixelBuffer)
    }
}
