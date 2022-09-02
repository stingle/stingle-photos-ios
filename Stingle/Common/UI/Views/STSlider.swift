//
//  STSlider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/30/21.
//

import UIKit

@IBDesignable class STSlider: UISlider {
    
    @IBInspectable var trackHeight: CGFloat = 4 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var thumbHeight: CGFloat = 4 {
        didSet {
            self.setNeedsDisplay()
        }
    }
        
    @IBInspectable var thumbNormalImage: UIImage? {
        set {
            self.setThumbImage(newValue, for: .normal)
        } get {
            return self.thumbImage(for: .normal)
        }
    }
    
    @IBInspectable var thumbHighlightedImage: UIImage? {
        set {
            self.setThumbImage(newValue, for: .highlighted)
        } get {
            return self.thumbImage(for: .highlighted)
        }
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var trackRect = super.trackRect(forBounds: bounds)
        trackRect.size.height = self.trackHeight
        return trackRect
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var bounds = bounds
        bounds.size.width = self.trackHeight
        bounds.size.height = self.trackHeight
        let trackRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        return trackRect
    }
    
}
