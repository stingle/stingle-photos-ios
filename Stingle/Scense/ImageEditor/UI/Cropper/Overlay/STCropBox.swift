//
//  STCropBox.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

class STCropBox: UIView {

    var gridLinesAlpha: CGFloat = 0 {
        didSet {
            self.gridLinesView.alpha = self.gridLinesAlpha
        }
    }

    var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = self.borderWidth
        }
    }

    lazy var gridLinesView: STGrid = {
        let view = STGrid(frame: bounds)
        view.backgroundColor = UIColor.clear
        view.alpha = 0
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleBottomMargin, .flexibleBottomMargin, .flexibleRightMargin]
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.autoresizingMask = UIView.AutoresizingMask(rawValue: 0)
        self.addSubview(self.gridLinesView)

        self.setupCorners()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.gridLinesView.frame = bounds
        self.gridLinesView.setNeedsDisplay()
    }

    func setupCorners() {
        let offset: CGFloat = -1

        let topLeft = CornerView(.topLeft)
        topLeft.center = CGPoint(x: offset, y: offset)
        topLeft.autoresizingMask = UIView.AutoresizingMask(rawValue: 0)
        self.addSubview(topLeft)

        let topRight = CornerView(.topRight)
        topRight.center = CGPoint(x: frame.size.width - offset, y: offset)
        topRight.autoresizingMask = .flexibleLeftMargin
        self.addSubview(topRight)

        let bottomRight = CornerView(.bottomRight)
        bottomRight.center = CGPoint(x: frame.size.width - offset, y: frame.size.height - offset)
        bottomRight.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        self.addSubview(bottomRight)

        let bottomLeft = CornerView(.bottomLeft)
        bottomLeft.center = CGPoint(x: offset, y: frame.size.height - offset)
        bottomLeft.autoresizingMask = .flexibleTopMargin
        self.addSubview(bottomLeft)
    }
}

// MARK: CornerType

extension STCropBox {
    enum CornerType {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

// MARK: CornerView

extension STCropBox {
    class CornerView: UIView {

        let cornerSize: CGFloat = 20

        init(_ type: CornerType) {
            super.init(frame: CGRect(x: 0, y: 0, width: self.cornerSize, height: self.cornerSize))

            self.backgroundColor = UIColor.clear

            let lineWidth: CGFloat = 2 + 1.0 / UIScreen.main.scale
            let lineColor: UIColor = .white

            let horizontal = UIView(frame: CGRect(x: 0, y: 0, width: self.cornerSize, height: lineWidth))
            horizontal.backgroundColor = lineColor
            self.addSubview(horizontal)

            let vertical = UIView(frame: CGRect(x: 0, y: 0, width: lineWidth, height: self.cornerSize))
            vertical.backgroundColor = lineColor
            self.addSubview(vertical)

            let shortMid = lineWidth / 2 // mid of short side of line rect
            let longMid = self.cornerSize / 2 // mid of long side of line rect

            switch type {
            case .topLeft:
                horizontal.center = CGPoint(x: longMid, y: shortMid)
                vertical.center = CGPoint(x: shortMid, y: longMid)
                self.layer.anchorPoint = CGPoint(x: shortMid / self.cornerSize, y: shortMid / self.cornerSize)
            case .topRight:
                horizontal.center = CGPoint(x: longMid, y: shortMid)
                vertical.center = CGPoint(x: self.cornerSize - shortMid, y: longMid)
                self.layer.anchorPoint = CGPoint(x: 1 - shortMid / self.cornerSize, y: shortMid / self.cornerSize)
            case .bottomLeft:
                horizontal.center = CGPoint(x: longMid, y: cornerSize - shortMid)
                vertical.center = CGPoint(x: shortMid, y: longMid)
                self.layer.anchorPoint = CGPoint(x: shortMid / self.cornerSize, y: 1 - shortMid / self.cornerSize)
            case .bottomRight:
                horizontal.center = CGPoint(x: longMid, y: self.cornerSize - shortMid)
                vertical.center = CGPoint(x: self.cornerSize - shortMid, y: longMid)
                self.layer.anchorPoint = CGPoint(x: 1 - shortMid / self.cornerSize, y: 1 - shortMid / self.cornerSize)
            }
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
