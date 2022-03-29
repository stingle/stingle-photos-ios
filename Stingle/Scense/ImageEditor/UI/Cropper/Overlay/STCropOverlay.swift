//
//  STCropOverlay.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

class STCropOverlay: UIView {

    var cropBoxAlpha: CGFloat {
        get {
            return self.cropBox.alpha
        }
        set {
            self.cropBox.alpha = newValue
        }
    }

    var gridLinesAlpha: CGFloat {
        get {
            return self.cropBox.gridLinesAlpha
        }
        set {
            self.cropBox.gridLinesAlpha = newValue
        }
    }

    var gridLinesCount: UInt = 2 {
        didSet {
            self.cropBox.gridLinesView.horizontalLinesCount = self.gridLinesCount
            self.cropBox.gridLinesView.verticalLinesCount = self.gridLinesCount
        }
    }

    var isBlurEnabled: Bool = true

    var blur: Bool = true {
        didSet {
            if self.blur, self.isBlurEnabled {
                self.translucentMaskView.effect = UIBlurEffect(style: .dark)
                self.translucentMaskView.backgroundColor = .clear
            } else {
                self.translucentMaskView.effect = nil
                self.translucentMaskView.backgroundColor = self.maskColor
            }
        }
    }

    // Take effect when blur = false
    var maskColor: UIColor = UIColor(white: 0.1, alpha: 0.3) {
        didSet {
            if !self.blur || !self.isBlurEnabled {
                self.translucentMaskView.backgroundColor = self.maskColor
            }
        }
    }

    var free: Bool = true {
        didSet {
            if self.free {
                self.cropBox.layer.borderWidth = 1
            } else {
                self.cropBox.layer.borderWidth = 2
            }
        }
    }

    var cropBoxFrame: CGRect {
        get {
            return self.cropBox.frame
        }
        set(frame) {
            self.cropBox.frame = frame
            self.updateMask(animated: false)
        }
    }

    func setCropBoxFrame(_ cropBoxFrame: CGRect, blurLayerAnimated: Bool) {
        self.cropBox.frame = cropBoxFrame
        self.updateMask(animated: blurLayerAnimated)
    }

    var cropBox = STCropBox(frame: .zero)

    lazy var translucentMaskView: UIVisualEffectView = {
        let vev = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        vev.backgroundColor = .clear
        vev.frame = self.bounds
        vev.isUserInteractionEnabled = false
        vev.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleHeight, .flexibleWidth]
        return vev
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false

        self.addSubview(self.translucentMaskView)
        self.addSubview(self.cropBox)

        self.gridLinesAlpha = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.translucentMaskView.frame = self.bounds
    }

    func updateMask(animated: Bool) {
        self.cropBox.layer.cornerRadius = 0
        self.cropBox.layer.masksToBounds = false

        var maskLayer: CAShapeLayer
        if let ml = self.translucentMaskView.layer.mask as? CAShapeLayer {
            maskLayer = ml
        } else {
            maskLayer = CAShapeLayer()
            self.translucentMaskView.layer.mask = maskLayer
        }

        let bezierPath = UIBezierPath(rect: self.translucentMaskView.bounds)
        let center = UIBezierPath(rect: self.cropBox.frame)
        bezierPath.append(center)

        maskLayer.fillRule = .evenOdd
        bezierPath.usesEvenOddFillRule = true

        if animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            maskLayer.path = bezierPath.cgPath
            animation.duration = 0.25
            maskLayer.add(animation, forKey: animation.keyPath)
        } else {
            maskLayer.path = bezierPath.cgPath
        }
    }
}
