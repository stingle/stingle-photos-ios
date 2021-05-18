//
//  STTabBar.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/29/21.
//

import UIKit

class STTabBar: UITabBar {
    
    private let seperator = UIView()
        
    @IBInspectable var seperatorColor: UIColor? {
        set {
            self.seperator.backgroundColor = newValue
        } get {
            return self.seperator.backgroundColor
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
    
    @IBInspectable var textColor: UIColor? = nil {
        didSet {
            let newColor = self.textColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.inlineLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
        }
    }
    
    @IBInspectable var iconColor: UIColor? = nil {
        didSet {
            let newColor = self.iconColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.normal.iconColor = newColor
            self.standardAppearance.inlineLayoutAppearance.normal.iconColor = newColor
            self.standardAppearance.compactInlineLayoutAppearance.normal.iconColor = newColor
        }
    }
    
    @IBInspectable var selectedTextColor: UIColor? = nil {
        didSet {
            let newColor = self.selectedTextColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.inlineLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
        }
    }
    
    @IBInspectable var focusedTextColor: UIColor? = nil {
        didSet {
            let newColor = self.focusedTextColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.focused.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.inlineLayoutAppearance.focused.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.compactInlineLayoutAppearance.focused.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
        }
    }
    
    @IBInspectable var selectedIconColor: UIColor? = nil {
        didSet {
            let newColor = self.selectedIconColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.selected.iconColor = newColor
            self.standardAppearance.inlineLayoutAppearance.selected.iconColor = newColor
            self.standardAppearance.compactInlineLayoutAppearance.selected.iconColor = newColor
        }
    }
    
    @IBInspectable var barBackroundColor: UIColor? {
        set {
            self.standardAppearance.backgroundColor = newValue
        } get {
            return self.standardAppearance.backgroundColor
        }
    }
    
    @IBInspectable var selectionIndicatorTintColor: UIColor? {
        set {
            self.standardAppearance.selectionIndicatorTintColor = newValue
        } get {
            return self.standardAppearance.selectionIndicatorTintColor
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    override var selectedItem: UITabBarItem? {
        didSet {
            UIView.animate(withDuration: 0.3) {
                self.updateFrame()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateFrame()
    }
    
    //MARK: - private
    
    private func setupView() {
        self.seperator.backgroundColor = UIColor.lightGray
        self.updateFrame()
        self.addSubview(self.seperator)

        let appearance = self.standardAppearance
        appearance.backgroundColor = self.barBackroundColor
        
        if UIDevice.current.userInterfaceIdiom != .tv {
            appearance.inlineLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.font] = UIFont.regular(light: 13)
            appearance.inlineLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.font] = UIFont.regular(light: 13)
        }
                        
        self.standardAppearance = appearance
    }
    
    private func updateFrame() {
        var itemFrame = self.frameForTabAtIndex()
        itemFrame.origin.y = 0
        itemFrame.size.height = 2
        self.seperator.frame = itemFrame
    }
    
    private func frameForTabAtIndex() -> CGRect {
        guard let index = self.items?.firstIndex(where: {$0 == self.selectedItem}) else { return .zero
        }
        var frames = self.subviews.compactMap { (view:UIView) -> CGRect? in
            if let view = view as? UIControl {
                return view.frame
            }
            return nil
        }
        frames.sort { $0.origin.x < $1.origin.x }
        if frames.count > index {
            return frames[index]
        }
        return frames.last ?? CGRect.zero
    }
    
    var accessoryView: UIView? {
        willSet {
            self.accessoryView?.removeFromSuperview()
        }
        didSet {
            self.subviews.forEach { view in
                view.isHidden = self.accessoryView != nil
            }
            if let accessoryView = self.accessoryView {
                accessoryView.frame = self.bounds
                self.addSubview(accessoryView)
                accessoryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                accessoryView.isHidden = false
            }
        }
    }
    

}
