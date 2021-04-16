//
//  STView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/29/21.
//

import UIKit

@IBDesignable
class STView: UIView {
    
    @IBInspectable var cornerTopLeft: Bool = true {
        didSet {
            self.setRadius()
        }
    }
    
    @IBInspectable var cornerTopRight: Bool = true {
        didSet {
            self.setRadius()
        }
    }
    
    @IBInspectable var cornerBottomLeft: Bool = true {
        didSet {
            self.setRadius()
        }
    }
    
    @IBInspectable var cornerBottomRight: Bool = true {
        didSet {
            self.setRadius()
        }
    }

    @IBInspectable var circle: Bool = false {
        didSet {
            self.setRadius()
        }
    }

    @IBInspectable var radius: CGFloat = 1 {
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
            self.layer.borderWidth = self.borderWidth

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

    @IBInspectable var borderColor: UIColor = UIColor.black {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    private var isUpdatingVarebles: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setRadius()
    }
    
    // MARK: - Private methods
    
    private func setRadius()  {
        guard self.isUpdatingVarebles == false else { return }
        var radius:CGFloat = 0
        if self.circle {
            radius = fmin(self.frame.size.height, self.frame.size.width);
            radius = radius/2
        }else if self.radius < 1 {
            radius = fmin(self.frame.size.height, self.frame.size.width);
            radius = radius * self.radius
        }else {
            radius = self.cornerRadius
        }
        self.roundCorners(radius: radius)
    }
    
    private func roundCorners(radius: CGFloat) {
        var corners: CACornerMask = []
        if self.cornerTopLeft {
            corners.update(with: CACornerMask.layerMinXMinYCorner)
        }
        if self.cornerTopRight {
            corners.update(with: CACornerMask.layerMaxXMinYCorner)
        }
        if self.cornerBottomLeft {
            corners.update(with: CACornerMask.layerMinXMaxYCorner)
        }
        if self.cornerBottomRight {
            corners.update(with: CACornerMask.layerMaxXMaxYCorner)
        }
        self.layer.maskedCorners = corners
        self.layer.cornerRadius = radius
    }

}


extension STView {
    
    func display(roundRect: RoundRect) {
        self.isUpdatingVarebles = true
        switch roundRect {
        case .top:
            self.cornerTopLeft = true
            self.cornerTopRight = true
            self.cornerBottomLeft = false
            self.cornerBottomRight = false
        case .bottom:
            self.cornerBottomLeft = true
            self.cornerBottomRight = true
            self.cornerTopLeft = false
            self.cornerTopRight = false
        case .left:
            self.cornerBottomLeft = true
            self.cornerTopLeft = true
            self.cornerBottomRight = false
            self.cornerTopRight = false
        case .right:
            self.cornerBottomLeft = false
            self.cornerTopLeft = false
            self.cornerBottomRight = true
            self.cornerTopRight = true
        case .all:
            self.cornerBottomLeft = true
            self.cornerBottomRight = true
            self.cornerTopLeft = true
            self.cornerTopRight = true
        case .none:
            self.cornerBottomLeft = false
            self.cornerBottomRight = false
            self.cornerTopLeft = false
            self.cornerTopRight = false
        }
        self.isUpdatingVarebles = false
        self.setRadius()
    }
    
}

extension UIView {
    
    enum RoundRect {
        case none
        case top
        case bottom
        case left
        case right
        case all
    }
    
}
