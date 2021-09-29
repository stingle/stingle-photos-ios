//
//  STButton.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/28/21.
//

import UIKit

@IBDesignable class STButton: UIButton {
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commitInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commitInit()
    }
        
    @IBInspectable var circle: Bool = false {
        didSet {
            self.setRadius()
        }
    }
    
    @IBInspectable var radius: CGFloat = 0.0 {
        didSet {
            self.setRadius()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.setRadius()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            self.layer.shadowRadius = shadowRadius
        }
    }
    
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0, height: 0) {
        didSet {
            self.layer.shadowOffset = shadowOffset
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 1.0 {
        didSet {
            self.layer.shadowOpacity = shadowOpacity
        }
    }
    
    @IBInspectable var shadowColor: UIColor = UIColor.clear {
        didSet {
            self.layer.shadowColor = shadowColor.cgColor
        }
    }
    
    @IBInspectable var borderColor: UIColor? = UIColor.clear {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var numberOfLines: Int = 1 {
        didSet {
            self.titleLabel?.lineBreakMode = .byWordWrapping
            self.titleLabel?.numberOfLines = self.numberOfLines
        }
    }
    
    @IBInspectable var titleMinimumScaleFactor: CGFloat {
        set {
            self.titleLabel?.adjustsFontSizeToFitWidth = true
            self.titleLabel?.minimumScaleFactor = newValue
        } get {
            return self.titleLabel?.minimumScaleFactor ?? 0
        }
    }
    
    override var isHighlighted: Bool {
        set {
            self.alpha = newValue ? 0.7 : 1
        } get {
            return false
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            self.alpha = self.isEnabled ? 1 : 0.7
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setRadius()
    }
    
    private func commitInit() {}
    
    func setSelected(_ isSelected: Bool, _ animation: Bool) {
        guard self.isSelected != isSelected else {
            return
        }
        if animation {
            let option = isSelected ? UIView.AnimationOptions.transitionFlipFromRight : UIView.AnimationOptions.transitionFlipFromLeft
            UIView.transition(with: self.imageView ?? self, duration: 0.3, options: option, animations: {
                self.isSelected = isSelected
            })
        } else {
            self.isSelected = isSelected
        }
    }
    
    func setRadius()  {
        if self.circle {
            let radiusBounds = fmin(self.bounds.size.height, self.bounds.size.width)
            let radiusFrame = fmin(self.frame.size.height, self.frame.size.width)
            let radius = fmin(radiusFrame, radiusBounds)
            self.layer.cornerRadius = radius/2
        }else if self.radius < 1 && self.radius > 0 {
            let radiusBounds = fmin(self.bounds.size.height, self.bounds.size.width)
            let radiusFrame = fmin(self.frame.size.height, self.frame.size.width)
            let radius = fmin(radiusFrame, radiusBounds) * self.radius
            self.layer.cornerRadius = radius
        }else {
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
}
