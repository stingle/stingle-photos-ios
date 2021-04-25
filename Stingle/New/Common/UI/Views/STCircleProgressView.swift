//
//  STCircleProgressView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/21/21.
//

import UIKit

@IBDesignable
class STCircleProgressView: UIView {
    
    @IBInspectable var startAngel: CGFloat = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var progress: CGFloat = 0.5 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var maxValue: CGFloat = 1 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var minValue: CGFloat = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var progressLineWidth: CGFloat = 2 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 4 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
   
    @IBInspectable var progressColor: UIColor = .systemBlue {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var trackColor: UIColor = .systemFill {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var image: UIImage? {
        set {
            self.imageView.image = newValue
            self.layoutIfNeeded()
        } get {
            return self.imageView.image
        }
    }
    
    override var tintColor: UIColor! {
        set {
            self.imageView.tintColor = newValue
        } get {
            return self.imageView.tintColor
        }
    }
    
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView()
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 55, height: 55)
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.frameforImageView()
        self.activityIndicator.frame = self.frameforActivityIndicator()
    }
    
    override func draw(_ rect: CGRect) {
        
        if self.progress == 0 {
            print("")
        } else if self.progress == 1 {
            print("")
        }
        
        let interval = self.maxValue - self.minValue
        let progressInterval = self.progress - self.minValue
        let progress = interval == .zero ? 0 : progressInterval / interval
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        self.drawCircle(rect, context: context, startAngel: 0, progress: 1, lineWidth: self.lineWidth, color: self.trackColor, clockwise: false)
                
        self.drawCircle(rect, context: context, startAngel: self.startAngel, progress: progress, lineWidth: self.progressLineWidth, color: self.progressColor, clockwise: false)
    }
    
    // MARK: - Public
    
    func startAnimating() {
        self.imageView.isHidden = true
        self.activityIndicator.startAnimating()
        self.layoutIfNeeded()
    }
    
    func stopAnimating() {
        self.imageView.isHidden = false
        self.activityIndicator.stopAnimating()
        self.layoutIfNeeded()
    }
        
    // MARK: - Private
    
    private func setup() {
        self.backgroundColor = .clear
        self.setupImageView()
        self.setupActivityIndicator()
    }
    
    private func setupImageView() {
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.imageView)
    }
    
    private func setupActivityIndicator() {
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.style = .medium
        self.addSubview(self.activityIndicator)
    }
    
    private func frameforImageView() -> CGRect {
        var frame = self.bounds
        let radius = min(frame.width, frame.height) / 2 - max(self.lineWidth, self.progressLineWidth)
        
        var width = sqrt(2 * radius * radius)
        var height = width
        
        if let image = self.imageView.image {
            width = min(width, image.size.width)
            height = min(height, image.size.height)
        }
        
        frame.size.width = width
        frame.size.height = height
        frame.origin.x = (self.bounds.width - frame.size.width) / 2
        frame.origin.y = (self.bounds.height - frame.size.height) / 2
        return frame
    }
    
    private func frameforActivityIndicator() -> CGRect {
        let size = self.activityIndicator.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var frame = CGRect.zero
        frame.size = size
        frame.origin.x = (self.bounds.width - size.width) / 2
        frame.origin.y = (self.bounds.height - size.height) / 2
        return frame
    }
    
    private func drawCircle(_ rect: CGRect, context: CGContext, startAngel: CGFloat, progress: CGFloat, lineWidth: CGFloat, color: UIColor, clockwise: Bool) {
        var progress = progress
        progress = max(progress, 0)
        progress = min(progress, 1)
        let endAngel = startAngel + 2 * CGFloat.pi * progress
        self.drawCircle(rect, context: context, startAngel: 0, endAngel: endAngel, lineWidth: lineWidth, color: color, clockwise: clockwise)
    }
    
    private func drawCircle(_ rect: CGRect, context: CGContext, startAngel: CGFloat, endAngel: CGFloat, lineWidth: CGFloat, color: UIColor, clockwise: Bool) {
        let path = CGMutablePath()
        let center = CGPoint(x: (rect.maxX - rect.minX) / 2, y: (rect.maxY - rect.minY) / 2)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        path.addArc(center: center, radius: radius, startAngle: startAngel, endAngle: endAngel, clockwise: clockwise)
        context.addPath(path)
        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        context.strokePath()
    }

}
