//
//  STCameraShutterButton.swift
//  Stingle
//
//  Stock-style shutter: a white ring with an inner disc that morphs to a red
//  square while recording.
//

import UIKit

final class STCameraShutterButton: UIControl {

    enum Style {
        case photo
        case video
        case recording
    }

    var style: Style = .photo {
        didSet { self.updateInner(animated: true) }
    }

    private let ringLayer = CAShapeLayer()
    private let innerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    private func commonInit() {
        self.ringLayer.fillColor = UIColor.clear.cgColor
        self.ringLayer.strokeColor = UIColor.white.cgColor
        self.ringLayer.lineWidth = 5
        self.layer.addSublayer(self.ringLayer)

        self.innerView.isUserInteractionEnabled = false
        self.innerView.backgroundColor = .white
        self.addSubview(self.innerView)

        self.addTarget(self, action: #selector(self.touchDown), for: .touchDown)
        self.addTarget(self, action: #selector(self.touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 3
        let ringRect = self.bounds.insetBy(dx: self.ringLayer.lineWidth / 2 + inset, dy: self.ringLayer.lineWidth / 2 + inset)
        self.ringLayer.path = UIBezierPath(ovalIn: ringRect).cgPath
        self.ringLayer.frame = self.bounds
        self.updateInner(animated: false)
    }

    private func updateInner(animated: Bool) {
        let work = {
            switch self.style {
            case .photo, .video:
                let innerInset: CGFloat = 10
                self.innerView.frame = self.bounds.insetBy(dx: innerInset, dy: innerInset)
                self.innerView.layer.cornerRadius = self.innerView.bounds.width / 2
                self.innerView.backgroundColor = self.style == .video ? .systemRed : .white
            case .recording:
                let side = self.bounds.width * 0.42
                self.innerView.bounds = CGRect(x: 0, y: 0, width: side, height: side)
                self.innerView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                self.innerView.layer.cornerRadius = 8
                self.innerView.backgroundColor = .systemRed
            }
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: work)
        } else {
            work()
        }
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) { self.innerView.alpha = 0.6 }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) { self.innerView.alpha = 1 }
    }
}
