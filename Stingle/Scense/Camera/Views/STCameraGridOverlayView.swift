//
//  STCameraGridOverlayView.swift
//  Stingle
//
//  Rule-of-thirds grid drawn over the preview.
//

import UIKit

final class STCameraGridOverlayView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(0.5)

        let thirdW = rect.width / 3
        let thirdH = rect.height / 3
        for index in 1...2 {
            let x = thirdW * CGFloat(index)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
            let y = thirdH * CGFloat(index)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
        }
        context.strokePath()
    }
}
