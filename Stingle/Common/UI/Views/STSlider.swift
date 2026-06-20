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
        if self.isMediaScrubberStyle {
            // Keep the (growing) track vertically centred.
            trackRect.origin.y = bounds.midY - trackRect.size.height / 2
        }
        return trackRect
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        if self.isMediaScrubberStyle {
            // Fixed-size circular thumb centred on the track regardless of its height.
            let thumb = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
            let diameter = self.scrubberThumbDiameter
            return CGRect(x: thumb.midX - diameter / 2, y: rect.midY - diameter / 2, width: diameter, height: diameter)
        }
        var bounds = bounds
        bounds.size.width = self.trackHeight
        bounds.size.height = self.trackHeight
        let trackRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        return trackRect
    }

    //MARK: - Media scrubber style (iOS Photos-like video seeker)

    private var isMediaScrubberStyle = false
    private let scrubberIdleHeight: CGFloat = 6
    private let scrubberActiveHeight: CGFloat = 11
    private let scrubberThumbDiameter: CGFloat = 13

    /// Opt-in styling that mimics the stock iOS Photos video scrubber: a rounded
    /// capsule track (white played / translucent unplayed) with a small white thumb
    /// that grows taller while the user is scrubbing. Off by default, so the other
    /// `STSlider`s (e.g. Settings) keep their current appearance.
    func applyMediaScrubberStyle() {
        self.isMediaScrubberStyle = true
        self.trackHeight = self.scrubberIdleHeight
        self.minimumTrackTintColor = .white
        self.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.25)
        let thumb = Self.circleImage(diameter: self.scrubberThumbDiameter, color: .white)
        self.setThumbImage(thumb, for: .normal)
        self.setThumbImage(thumb, for: .highlighted)
        self.setNeedsLayout()
    }

    private func setScrubbing(_ scrubbing: Bool) {
        self.trackHeight = scrubbing ? self.scrubberActiveHeight : self.scrubberIdleHeight
        UIView.animate(withDuration: 0.2) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private static func circleImage(diameter: CGFloat, color: UIColor) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        return UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let result = super.beginTracking(touch, with: event)
        if self.isMediaScrubberStyle {
            self.setScrubbing(true)
        }
        return result
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        if self.isMediaScrubberStyle {
            self.setScrubbing(false)
        }
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        if self.isMediaScrubberStyle {
            self.setScrubbing(false)
        }
    }

}
