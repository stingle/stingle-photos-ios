//
//  LockedCaptureView.swift
//  StingleCameraCapture
//
//  Minimal stock-like capture UI shown over the device lock screen.
//

import SwiftUI
import AVFoundation
import LockedCameraCapture
import StingleRoot

@available(iOS 18.0, *)
struct LockedCaptureView: View {

    let session: LockedCameraCaptureSession
    @StateObject private var controller = LockedCaptureController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreviewRepresentable(session: controller.engine.captureSession)
                .ignoresSafeArea()

            VStack {
                Spacer()
                // Mode picker (compact).
                HStack(spacing: 18) {
                    ForEach(controller.availableModes, id: \.rawValue) { mode in
                        Button(action: { controller.setMode(mode) }) {
                            Text(self.title(for: mode))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(mode == controller.mode ? .yellow : .white)
                        }
                    }
                }
                .padding(.bottom, 12)

                HStack {
                    if let thumb = controller.lastThumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Color.clear.frame(width: 48, height: 48)
                    }
                    Spacer()
                    Button(action: { controller.shutter() }) {
                        ZStack {
                            Circle().stroke(Color.white, lineWidth: 5).frame(width: 72, height: 72)
                            Circle()
                                .fill(controller.isRecording ? Color.red : Color.white)
                                .frame(width: controller.isRecording ? 32 : 58,
                                       height: controller.isRecording ? 32 : 58)
                        }
                    }
                    Spacer()
                    Button(action: { controller.switchPosition() }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .onAppear { controller.start() }
        .onDisappear { controller.stop() }
    }

    private func title(for mode: STCameraMode) -> String {
        switch mode {
        case .photo: return "PHOTO"
        case .video: return "VIDEO"
        case .slowmo: return "SLO-MO"
        case .timelapse: return "TIME-LAPSE"
        case .portrait: return "PORTRAIT"
        }
    }
}

@available(iOS 18.0, *)
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = self.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = self.session
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { self.layer as! AVCaptureVideoPreviewLayer }
    }
}
