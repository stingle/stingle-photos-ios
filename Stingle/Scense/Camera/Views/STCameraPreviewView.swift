//
//  STCameraPreviewView.swift
//  Stingle
//
//  A view backed by AVCaptureVideoPreviewLayer plus tap-to-focus / pinch-to-zoom.
//

import UIKit
import AVFoundation

protocol STCameraPreviewViewDelegate: AnyObject {
    func previewView(_ view: STCameraPreviewView, didTapToFocusAt devicePoint: CGPoint, viewPoint: CGPoint)
    func previewView(_ view: STCameraPreviewView, didPinchToZoom scale: CGFloat, state: UIGestureRecognizer.State)
}

final class STCameraPreviewView: UIView {

    weak var delegate: STCameraPreviewViewDelegate?

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer { self.layer as! AVCaptureVideoPreviewLayer }

    var session: AVCaptureSession? {
        get { self.previewLayer.session }
        set {
            self.previewLayer.session = newValue
            self.previewLayer.videoGravity = .resizeAspectFill
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    private func commonInit() {
        self.backgroundColor = .black
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        self.addGestureRecognizer(pinch)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let devicePoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        self.delegate?.previewView(self, didTapToFocusAt: devicePoint, viewPoint: point)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        self.delegate?.previewView(self, didPinchToZoom: gesture.scale, state: gesture.state)
    }
}
