//
//  STRulerView.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/29/21.
//

import UIKit

protocol STRulerViewDelegate: AnyObject {
    func angleRuleDidChangeValue(value: CGFloat)
    func angleRuleDidEndEditing()
}

extension STRulerViewDelegate {
    func angleRuleDidEndEditing() {}
}

class STRulerView: UIControl {

    enum Direction: Int {
        case horizontal = 0
        case vertical
    }

    var direction: Direction = .horizontal
    var minimumValue: CGFloat = -100
    var maximumValue: CGFloat = 100
    var defaultValue: CGFloat = 0 {
        didSet {
            self.correctZeroDotFrame()
        }
    }

    weak var delegate: STRulerViewDelegate?

    var value: CGFloat {
        get {
            return self._value
        }
        set {
            self.setValue(newValue, sendEvent: false)
        }
    }

    private lazy var midScaleLine: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 30))
        view.backgroundColor = .white
        view.center = CGPoint(x: self.frame.size.width / 2.0 + self.pixelOffset, y: self.frame.size.height - 15)
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView(frame: self.bounds)
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = .clear
        sv.decelerationRate = .fast
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.delegate = self
        return sv
    }()

    private lazy var zeroDot: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        view.backgroundColor = .white
        return view
    }()

    private var scaleSpacing: CGFloat = 9
    private var numberOfTotalScales: Int = 40
    private var numberOfGroupedScales: Int = 10

    private let lineName = "line"
    private let margin: CGFloat = 15
    private let borderWidth: CGFloat = 1.0 / UIScreen.main.scale
    private lazy var pixelOffset = CGFloat(0.5.truncatingRemainder(dividingBy: Double(self.borderWidth)))

    private var scrollViewContentInset: CGFloat {
        switch self.direction {
        case .horizontal:
            return self.scrollView.frame.size.width / 2.0
        case .vertical:
            return self.scrollView.frame.size.height / 2.0
        }
    }

    private var _value: CGFloat = 0 {
        didSet {
            if abs(_value) < 0.01 {
                self.zeroDot.isHidden = true
            } else {
                self.zeroDot.isHidden = false
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.scrollView.addSubview(self.zeroDot)
        self.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        self.addSubview(self.midScaleLine)
        self.setDirection(direction: .horizontal)
        self.setValue(0, sendEvent: false)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self {
            return self.scrollView
        }

        return view
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        switch self.direction {
        case .horizontal:
            let center = CGPoint(x: self.frame.size.width / 2.0 + self.pixelOffset, y: self.frame.size.height - 15)
            let size = CGSize(width: 1.0, height: 30.0)
            self.midScaleLine.frame = CGRect(center: center, size: size)
        case .vertical:
            let center = CGPoint(x: self.frame.size.width - 15, y: self.frame.size.height / 2.0 + self.pixelOffset)
            let size = CGSize(width: 30.0, height: 1.0)
            self.midScaleLine.frame = CGRect(center: center, size: size)
        }
        self.correctZeroDotFrame()
    }

    func setDirection(direction: Direction) {
        self.direction = direction
        switch self.direction {
        case .horizontal:
            self.setupScaleLayers()
        case .vertical:
            self.setupScaleLayers()
        }
        self.setNeedsLayout()
    }

    // MARK: - Private methods

    private func setValue(_ newValue: CGFloat, sendEvent: Bool) {
        self._value = newValue
        var x: CGFloat = CGFloat(self.numberOfTotalScales) * self.scaleSpacing * (newValue - self.minimumValue) / (self.maximumValue - self.minimumValue)
        var y: CGFloat = 0.0
        if self.direction == .vertical {
            x = CGFloat(self.numberOfTotalScales) * self.scaleSpacing * (self.maximumValue - newValue) / (self.maximumValue - self.minimumValue)
            swap(&x, &y)
        }
        if sendEvent {
            self.scrollView.contentOffset = CGPoint(x: x, y: y)
        } else {
            self.scrollView.delegate = nil
            self.scrollView.contentOffset = CGPoint(x: x, y: y)
            self.scrollView.delegate = self
        }
    }

    private func createShapeLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.name = self.lineName
        layer.lineWidth = 1
        layer.fillColor = UIColor.clear.cgColor
        return layer
    }

    private func setupScaleLayers() {
        self.scrollView.layer.sublayers?.forEach { layer in
            if layer.name == self.lineName {
                layer.removeFromSuperlayer()
            }
        }
        let grayScales = self.createShapeLayer()
        grayScales.strokeColor = UIColor(white: 0.5, alpha: 1).cgColor
        let grayPath = CGMutablePath()

        let whiteScales = self.createShapeLayer()
        whiteScales.strokeColor = UIColor(white: 1, alpha: 1).cgColor
        let whitePath = CGMutablePath()

        let scaleBorders = self.createShapeLayer()
        scaleBorders.strokeColor = UIColor(white: 0, alpha: 0.2).cgColor
        scaleBorders.lineWidth = 1 + 2 * self.borderWidth
        let borderPath = CGMutablePath()

        let lineHeight: CGFloat = 10
        let lineBottom = self.direction == .vertical ? self.frame.size.width : self.frame.size.height
        let lineTop = lineBottom - lineHeight

        for i in 0...self.numberOfTotalScales {
            switch self.direction {
            case .horizontal:
                let x = CGFloat(i) * self.scaleSpacing + self.pixelOffset + self.scrollViewContentInset
                if i % self.numberOfGroupedScales == 0 {
                    whitePath.move(to: CGPoint(x: x, y: lineTop))
                    whitePath.addLine(to: CGPoint(x: x, y: lineBottom))
                } else {
                    grayPath.move(to: CGPoint(x: x, y: lineTop))
                    grayPath.addLine(to: CGPoint(x: x, y: lineBottom))
                }
                borderPath.move(to: CGPoint(x: x, y: lineTop - self.borderWidth))
                borderPath.addLine(to: CGPoint(x: x, y: lineBottom + self.borderWidth))
            case .vertical:
                let y = CGFloat(i) * self.scaleSpacing + self.pixelOffset + self.scrollViewContentInset
                if i % self.numberOfGroupedScales == 0 {
                    whitePath.move(to: CGPoint(x: lineTop, y: y))
                    whitePath.addLine(to: CGPoint(x: lineBottom, y: y))
                } else {
                    grayPath.move(to: CGPoint(x: lineTop, y: y))
                    grayPath.addLine(to: CGPoint(x: lineBottom, y: y))
                }
                borderPath.move(to: CGPoint(x: lineTop - self.borderWidth, y: y))
                borderPath.addLine(to: CGPoint(x: lineBottom + self.borderWidth, y: y))
            }
        }

        grayScales.path = grayPath
        whiteScales.path = whitePath
        scaleBorders.path = borderPath
        self.scrollView.layer.addSublayer(scaleBorders)
        self.scrollView.layer.addSublayer(whiteScales)
        self.scrollView.layer.addSublayer(grayScales)
        let size = CGSize(width: CGFloat(self.numberOfTotalScales) * self.scaleSpacing + 2 * self.scrollViewContentInset, height: 40.0)
        switch self.direction {
        case .horizontal:
            self.scrollView.contentSize = size
        case .vertical:
            self.scrollView.contentSize = CGSize(width: size.height, height: size.width)
        }
    }

    private func autoZeroValue() {
        if abs(self.value) < 1 {
            UIView.animate(withDuration: 0.15) {
                self.setValue(0, sendEvent: true)
            }
        }
    }

    private func scrollEnded() {
        self.midScaleLine.backgroundColor = .white
        self.autoZeroValue()
        self.delegate?.angleRuleDidEndEditing()
    }

    private func correctZeroDotFrame() {
        switch self.direction {
        case .horizontal:
            let coefficient = (abs(self.minimumValue) + self.defaultValue) / max(1, abs(self.maximumValue - self.minimumValue))
            let point = (CGFloat(self.numberOfTotalScales) * coefficient) * self.scaleSpacing + self.pixelOffset + self.scrollViewContentInset - 3
            self.zeroDot.frame = CGRect(x: point, y: self.frame.size.height - self.midScaleLine.frame.height, width: 6, height: 6)
        case .vertical:
            let coefficient = (abs(self.minimumValue) + self.defaultValue) / max(1, abs(self.maximumValue - self.minimumValue))
            let point = (CGFloat(self.numberOfTotalScales) * (1 - coefficient)) * self.scaleSpacing + self.pixelOffset + self.scrollViewContentInset - 3
            self.zeroDot.frame = CGRect(x: self.frame.size.width - self.midScaleLine.frame.width, y: point, width: 6, height: 6)
        }
    }

}

extension STRulerView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = self.direction == .vertical ? scrollView.contentOffset.y : scrollView.contentOffset.x
        var value = offset * (self.maximumValue - self.minimumValue) / (CGFloat(self.numberOfTotalScales) * self.scaleSpacing)
        switch self.direction {
        case .horizontal:
            value += self.minimumValue
        case .vertical:
            value = self.maximumValue - value
        }
        if value < self.minimumValue {
            value = self.minimumValue
        }
        if value > self.maximumValue {
            value = self.maximumValue
        }
        self._value = value
        self.midScaleLine.backgroundColor = UIColor(red: 249 / 255.0, green: 214 / 255.0, blue: 74 / 255.0, alpha: 1)
        self.delegate?.angleRuleDidChangeValue(value: value)
    }

    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.scrollEnded()
        }
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        self.scrollEnded()
    }

    func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        self.scrollEnded()
    }
}
