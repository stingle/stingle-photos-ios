//
//  STCropBox+Grid.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

extension STCropBox {
 
    class Grid: UIView {

        var horizontalLinesCount: UInt = 2 {
            didSet {
                self.setNeedsDisplay()
            }
        }

        var verticalLinesCount: UInt = 2 {
            didSet {
                self.setNeedsDisplay()
            }
        }

        var lineColor: UIColor = UIColor(white: 1, alpha: 0.7) {
            didSet {
                self.setNeedsDisplay()
            }
        }

        var lineWidth: CGFloat = 1.0 / UIScreen.main.scale {
            didSet {
                self.setNeedsDisplay()
            }
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)

            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }

            context.setLineWidth(self.lineWidth)
            context.setStrokeColor(self.lineColor.cgColor)

            let horizontalLineSpacing = frame.size.width / CGFloat(self.horizontalLinesCount + 1)
            let verticalLineSpacing = frame.size.height / CGFloat(self.verticalLinesCount + 1)

            for i in 1 ..< self.horizontalLinesCount + 1 {
                context.move(to: CGPoint(x: CGFloat(i) * horizontalLineSpacing, y: 0))
                context.addLine(to: CGPoint(x: CGFloat(i) * horizontalLineSpacing, y: frame.size.height))
            }

            for i in 1 ..< self.verticalLinesCount + 1 {
                context.move(to: CGPoint(x: 0, y: CGFloat(i) * verticalLineSpacing))
                context.addLine(to: CGPoint(x: frame.size.width, y: CGFloat(i) * verticalLineSpacing))
            }

            context.strokePath()
        }
    }

}
