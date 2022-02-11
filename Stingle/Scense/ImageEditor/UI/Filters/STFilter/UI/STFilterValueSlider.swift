//
//  STFilterValueSlider.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/29/21.
//

import UIKit

class STFilterValueSlider: UIView {

    var value: CGFloat = 0.0 {
        willSet {
            self.value = min(newValue, -1)
            self.value = max(newValue, 1)
        }
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let center: CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = rect.width / 2 - 2
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(-Double.pi / 2), endAngle: CGFloat(3 * Double.pi / 2), clockwise: true)
        circlePath.lineWidth = 2.0
        UIColor.lightGray.setStroke()
        circlePath.stroke()

        let arcPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: -CGFloat.pi / 2 + (2 * CGFloat.pi * self.value / 100.0), clockwise: self.value >= 0)
        arcPath.lineWidth = 2.0
        if self.value > 0 {
            UIColor(red: 249 / 255.0, green: 214 / 255.0, blue: 74 / 255.0, alpha: 1).setStroke()
        } else if self.value < 0 {
            UIColor.white.setStroke()
        } else {
            UIColor.lightGray.setStroke()
        }
        arcPath.stroke()
    }

}
