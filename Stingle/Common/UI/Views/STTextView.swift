//
//  STTextView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/15/21.
//

import UIKit

protocol STTextViewDelegate: UITextViewDelegate {
    func textView(textView: STTextView, didChangeText: String?)
}

@IBDesignable
@objc(STTextView)
public class STTextView: UITextView {
    
    // MARK: - Private Properties
    
    private let placeholderView = UITextView(frame: CGRect.zero)
    
    @IBInspectable public var placeholderTextColor: UIColor {
        get {
            return placeholderView.textColor!
        }
        set {
            placeholderView.textColor = newValue
        }
    }
    
    @IBInspectable public var placeholder: String? {
        get {
            return placeholderView.text
        }
        set {
            placeholderView.text = newValue
            setNeedsLayout()
        }
    }
    
    @IBInspectable var selectedUnderlineColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var underlineColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var underlineHeight: CGFloat = 1 {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    private(set) var isKeyboardVisible = false
    
    public var attributedPlaceholder: NSAttributedString? {
        get {
            return placeholderView.attributedText
        }set {
            placeholderView.attributedText = newValue
            setNeedsLayout()
        }
    }
    
    /// Returns true if the placeholder is currently showing.
    public var isShowingPlaceholder: Bool {
        return placeholderView.superview != nil
    }
    
    public var optimalSize: CGSize {
        return self.intrinsicContentSize
    }
    
    // MARK: - Observed Properties
    
    override public var text: String! {
        didSet {
            showPlaceholderViewIfNeeded()
        }
    }
    
    override public var attributedText: NSAttributedString! {
        didSet {
            showPlaceholderViewIfNeeded()
        }
    }
    
    override public var font: UIFont! {
        didSet {
            placeholderView.font = font
        }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet {
            placeholderView.textAlignment = textAlignment
        }
    }
    
    override public var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderView.textContainerInset = textContainerInset
        }
    }
    
    override public var intrinsicContentSize: CGSize {
        get {
            var size = CGSize.zero
            if isShowingPlaceholder {
                size = placeholderSize()
            } else {
                let fixedWidth = self.frame.size.width
                size = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            }
            size.height = size.height + self.underlineHeight
            return size
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        resizePlaceholderView()
    }
    
    // MARK: - Initialization
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupPlaceholderView()
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholderView()
    }
    
    public override func becomeFirstResponder() -> Bool {
        self.isKeyboardVisible = true
        self.setNeedsDisplay()
        return super.becomeFirstResponder()
    }
   
    public override func resignFirstResponder() -> Bool {
        self.isKeyboardVisible = false
        self.setNeedsDisplay()
        return super.resignFirstResponder()
    }
    
    public override func draw(_ rect: CGRect) {
        let color = (self.isKeyboardVisible ? self.selectedUnderlineColor : self.underlineColor) ?? self.underlineColor
        guard let context = UIGraphicsGetCurrentContext(), let drawColor = color else {
            return
        }
        let rect = CGRect(x: 0, y: (rect.height - self.underlineHeight) + rect.origin.y, width: rect.width, height: self.underlineHeight)
        let path = CGPath(roundedRect: rect, cornerWidth: 0.5, cornerHeight: 0.5, transform: nil)
        context.addPath(path)
        context.setFillColor(drawColor.cgColor)
        context.fillPath()
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - Notification
    
    @objc func textDidChange(notification: NSNotification) {
        guard (notification.object as? STTextView) == self else {
            return
        }
                
        showPlaceholderViewIfNeeded()
        self.setNeedsDisplay()
        self.invalidateIntrinsicContentSize()
        (self.delegate as? STTextViewDelegate)?.textView(textView: self, didChangeText: self.text)
    }
    
    // MARK: - Placeholder
    
    private func setupPlaceholderView() {
        placeholderView.isOpaque = false
        placeholderView.backgroundColor = UIColor.clear
        placeholderView.textColor = UIColor(white: 0.7, alpha: 1.0)
        
        placeholderView.isScrollEnabled = true
        placeholderView.isUserInteractionEnabled = false
        placeholderView.isAccessibilityElement = false
        placeholderView.isSelectable = false
        
        showPlaceholderViewIfNeeded()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(textDidChange(notification:)), name: UITextView.textDidChangeNotification, object: self)
    }
    
    private func showPlaceholderViewIfNeeded() {
        if text != nil && !text.isEmpty {
            if isShowingPlaceholder {
                placeholderView.removeFromSuperview()
                invalidateIntrinsicContentSize()
                setContentOffset(CGPoint.zero, animated: false)
            }
        } else {
            if !isShowingPlaceholder {
                addSubview(placeholderView)
                invalidateIntrinsicContentSize()
                setContentOffset(CGPoint.zero, animated: false)
            }
        }
    }
    
    private func resizePlaceholderView() {
        if isShowingPlaceholder {
            let size = placeholderSize()
            let frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
            
            if !placeholderView.frame.equalTo(frame) {
                placeholderView.frame = frame
                invalidateIntrinsicContentSize()
            }
            contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: size.height - contentSize.height, right: 0.0)
        } else {
            contentInset = .zero
        }
    }
    
    private func placeholderSize() -> CGSize {
        var maxSize = self.bounds.size
        maxSize.height = CGFloat.greatestFiniteMagnitude
        return placeholderView.sizeThatFits(maxSize)
    }

}
