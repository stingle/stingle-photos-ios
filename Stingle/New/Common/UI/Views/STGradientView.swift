//
//  STGradientView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import UIKit

private class STGradientLayer: CALayer {
    
    @objc var priority: CGFloat = 0.5
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(STGradientLayer.priority) {
            return true
        }
        
        if key == #keyPath(STGradientLayer.opacity) {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        guard let keys = self.animationKeys(), keys.count > 0 else {
            return
        }
        (self.delegate as? STGradientView)?.setNeedsDisplay()
    }
}

@IBDesignable class STGradientView: UIView {
    
    enum GradientDrawOptions: Int {
        case CenterTopCenterBottom = 0
        case CenterLeftCenterRight = 1
        case TopLeftBottomRight = 2
        case TopRightBottomLeft = 3
    }
    
    enum GradientDrawStyle: Int {
        case linear
        case radial
    }
    
    @IBInspectable var drawOptions: Int = GradientDrawOptions.CenterTopCenterBottom.rawValue {
        didSet {
            self.drawOptions = self.drawOptions > GradientDrawOptions.TopRightBottomLeft.rawValue ? GradientDrawOptions.TopRightBottomLeft.rawValue : self.drawOptions
            self.drawOptions = self.drawOptions < GradientDrawOptions.CenterTopCenterBottom.rawValue ? GradientDrawOptions.CenterTopCenterBottom.rawValue : self.drawOptions
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var drawStyle: Int = 0 {
        didSet {
            self.drawStyle = self.drawStyle > GradientDrawStyle.radial.rawValue ? GradientDrawStyle.radial.rawValue : self.drawStyle
            self.drawStyle = self.drawStyle < GradientDrawStyle.linear.rawValue ? GradientDrawStyle.linear.rawValue : self.drawStyle
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var priority: CGFloat  {
        set {
            (self.layer as? STGradientLayer)?.priority = newValue
            self.setNeedsDisplay()
        } get {
            return (self.layer as? STGradientLayer)!.priority
        }

    }
    
    @IBInspectable var clearColors: Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    #if !TARGET_INTERFACE_BUILDER
    
    var colors: [UIColor] = [UIColor.blue] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    #else
    var colors: [UIColor] = [UIColor.clear, UIColor.blue.withAlphaComponent(0.4)] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    #endif
    
    private var animation: CABasicAnimation?
    
    override public class var layerClass: Swift.AnyClass {
        return STGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setNeedsDisplay()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.updateGradientAnimation()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        if !self.clearColors {
            self.drawGradient(context: context, rect: rect)
        }
    }
    
    //MARK - public
    
    func updateGradientAnimation() {
        self.setNeedsDisplay()
        if let anime = self.animation, self.window != nil {
            self.layer.add(anime, forKey: anime.keyPath)
        }
    }
    
    func addPriorityAnimation(priority: CGFloat, duration: TimeInterval, repeatCount: Float = .infinity)  {
        self.layer.removeAllAnimations()
        let anim = CABasicAnimation(keyPath: "priority")
        anim.fromValue = self.priority
        anim.toValue = priority
        anim.duration = duration
        anim.repeatCount = repeatCount
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        self.animation = anim
        self.layer.add(anim, forKey: "priority")
    }
    
    func addAlphaAnimation(fromValue: CGFloat, byValue: CGFloat? = nil, toValue: CGFloat, duration: TimeInterval, repeatCount: Float = .infinity) {
        self.layer.removeAllAnimations()
        self.layer.opacity = Float(byValue ?? CGFloat(self.layer.opacity))
        
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = fromValue
        anim.toValue = toValue
        anim.byValue = NSValue(nonretainedObject: self.layer.opacity)
        anim.duration = duration
        anim.repeatCount = repeatCount
        
        if let byValue = byValue {
            anim.fillMode = CAMediaTimingFillMode.backwards
            let beginTime = TimeInterval((byValue - fromValue) / (toValue - fromValue)) * duration
            anim.beginTime = CACurrentMediaTime() + beginTime
        }
                    
        anim.autoreverses = true
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        self.animation = anim
        self.layer.add(anim, forKey: "opacity")
    }
    
    func removeAllAnimation()  {
        self.layer.removeAllAnimations()
    }
    
    func addFadeAnimation() {
        let fromValue: CGFloat = 0.5
        let toValue: CGFloat = 1
        let byValue: CGFloat = Bool.random() ? fromValue : toValue
        self.addAlphaAnimation(fromValue: fromValue, byValue: byValue, toValue: toValue, duration: 1)
    }
    
    //MARK - private
    
    private func setup()  {
        NotificationCenter.default.addObserver(self, selector: #selector(enterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func drawGradient(context: CGContext, rect: CGRect)  {
        let colors = self.cgColor()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations = self.gradientColorLocations()
        let cfArrayColors = (colors as CFArray)
        let gradient = CGGradient(colorsSpace: colorSpace, colors: cfArrayColors, locations: colorLocations)
        
        if let gradient = gradient {
            let points = self.getDrawOptionsLocations(in: rect)
            if self.drawStyle == GradientDrawStyle.linear.rawValue {
                context.drawLinearGradient(gradient,  start: points.startPoint, end: points.endPoint,options:[.drawsBeforeStartLocation])
            } else {
                let radius = max(rect.width, rect.height)/2
                context.drawRadialGradient(gradient, startCenter: points.startPoint, startRadius: 0, endCenter: points.endPoint, endRadius: radius, options: [.drawsAfterEndLocation])
            }
        }
    }
    
    private func gradientColorLocations() -> [CGFloat] {
        let distance: CGFloat = 1.0/CGFloat(colors.count)
        var result: [CGFloat] = [CGFloat]()
        
        for index in 0..<colors.count {
            var value = (self.priority - distance * CGFloat(colors.count - 1 - index)) * CGFloat(colors.count)
            value = value > 1 ? 1 : value
            value = value < 0 ? 0 : value
            result.append(value)
        }
        
        return result
    }
    
    private func getDrawOptionsLocations(in frame: CGRect) -> (startPoint: CGPoint, endPoint: CGPoint) {
        
        guard self.drawStyle == GradientDrawStyle.linear.rawValue else {
            let point: CGPoint = CGPoint(x: frame.width/2, y: frame.height/2)
            return (point, point)
        }
        
        switch drawOptions {
        case GradientDrawOptions.CenterTopCenterBottom.rawValue:
            let point1: CGPoint = CGPoint(x: frame.width/2, y: 0)
            let point2: CGPoint = CGPoint(x: frame.width/2, y: frame.height)
            return (point1, point2)
        case GradientDrawOptions.CenterLeftCenterRight.rawValue:
            let point1: CGPoint = CGPoint(x: 0, y: frame.height/2)
            let point2: CGPoint = CGPoint(x: frame.width, y: frame.height/2)
            return (point1, point2)
        case GradientDrawOptions.TopLeftBottomRight.rawValue:
            let point1: CGPoint = CGPoint(x: 0, y: 0)
            let point2: CGPoint = CGPoint(x: frame.width, y: frame.height)
            return (point1, point2)
        case GradientDrawOptions.TopRightBottomLeft.rawValue:
            let point1: CGPoint = CGPoint(x: frame.width, y: 0)
            let point2: CGPoint = CGPoint(x: 0, y: frame.height)
            return (point1, point2)
        default:
            return (CGPoint.zero, CGPoint.zero)
        }
    }
    
    private func cgColor() -> [CGColor] {
        var cgColorArray: [CGColor] = []
        for color in self.colors {
            cgColorArray.append(color.cgColor)
        }
        return cgColorArray
    }
    
    @objc private func enterForeground(notification: Notification) {
        self.updateGradientAnimation()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
}

extension STGradientView {
    
    @IBInspectable var primaryColor: UIColor? {
        get {
            return self.colors.first
        } set {
            var newColors = [UIColor]()
            if let primaryColor = newValue {
                newColors.append(primaryColor)
            }
            if let secondaryColor = self.secondaryColor {
                newColors.append(secondaryColor)
            }
            self.colors = newColors
        }
    }
    
    @IBInspectable var secondaryColor: UIColor? {
        get {
            return self.colors.last
        } set {
            var newColors = [UIColor]()
            if let primaryColor = self.primaryColor {
                newColors.append(primaryColor)
            }
            if let secondaryColor = newValue {
                newColors.append(secondaryColor)
            }
            self.colors = newColors
        }
    }
    
}
