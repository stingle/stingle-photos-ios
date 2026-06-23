//
//  STTimeLapseAssembler.swift
//  StingleRoot
//
//  Incrementally writes sampled frames into an mp4 with AVAssetWriter so a
//  time-lapse never accumulates all frames in memory.
//

import AVFoundation
import CoreVideo

final class STTimeLapseAssembler {

    let outputURL: URL
    private let playbackFrameRate: Int32
    private let preferHEVC: Bool

    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var frameIndex: Int64 = 0
    private var started = false

    var frameCount: Int64 { self.frameIndex }

    init(outputURL: URL, playbackFrameRate: Int32 = 30, preferHEVC: Bool = true) {
        self.outputURL = outputURL
        self.playbackFrameRate = playbackFrameRate
        self.preferHEVC = preferHEVC
    }

    private func startIfNeeded(width: Int, height: Int) -> Bool {
        guard !self.started else { return true }
        do {
            let writer = try AVAssetWriter(outputURL: self.outputURL, fileType: .mp4)
            let codec: AVVideoCodecType = self.preferHEVC ? .hevc : .h264
            let settings: [String: Any] = [
                AVVideoCodecKey: codec,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = false
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)
            guard writer.canAdd(input) else { return false }
            writer.add(input)
            guard writer.startWriting() else { return false }
            writer.startSession(atSourceTime: .zero)
            self.writer = writer
            self.input = input
            self.adaptor = adaptor
            self.started = true
            return true
        } catch {
            return false
        }
    }

    /// Appends one sampled frame. Safe to call from the capture sample-buffer queue.
    @discardableResult
    func append(pixelBuffer: CVPixelBuffer) -> Bool {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard self.startIfNeeded(width: width, height: height),
              let input = self.input, let adaptor = self.adaptor,
              input.isReadyForMoreMediaData else {
            return false
        }
        let time = CMTimeMake(value: self.frameIndex, timescale: self.playbackFrameRate)
        let ok = adaptor.append(pixelBuffer, withPresentationTime: time)
        if ok { self.frameIndex += 1 }
        return ok
    }

    func finish(completion: @escaping (_ success: Bool) -> Void) {
        guard self.started, let writer = self.writer, let input = self.input, self.frameIndex > 0 else {
            completion(false)
            return
        }
        input.markAsFinished()
        writer.finishWriting {
            completion(writer.status == .completed)
        }
    }

    func cancel() {
        self.input?.markAsFinished()
        self.writer?.cancelWriting()
    }
}
