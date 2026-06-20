//
//  STTabBar.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/29/21.
//

import UIKit

class STTabBar: UITabBar {
    
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
            self.reloadScrollEdgeAppearance()
        }
    }
    
    @IBInspectable var textColor: UIColor? = nil {
        didSet {
            let newColor = self.textColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.inlineLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.reloadScrollEdgeAppearance()
        }
    }
    
    @IBInspectable var iconColor: UIColor? = nil {
        didSet {
            let newColor = self.iconColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.normal.iconColor = newColor
            self.standardAppearance.inlineLayoutAppearance.normal.iconColor = newColor
            self.standardAppearance.compactInlineLayoutAppearance.normal.iconColor = newColor
            self.reloadScrollEdgeAppearance()
        }
    }
    
    @IBInspectable var selectedTextColor: UIColor? = nil {
        didSet {
            let newColor = self.selectedTextColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.inlineLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.reloadScrollEdgeAppearance()
        }
    }
    
    @IBInspectable var focusedTextColor: UIColor? = nil {
        didSet {
            let newColor = self.focusedTextColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.focused.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.inlineLayoutAppearance.focused.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.standardAppearance.compactInlineLayoutAppearance.focused.titleTextAttributes[NSAttributedString.Key.foregroundColor] = newColor
            self.reloadScrollEdgeAppearance()
        }
    }
    
    @IBInspectable var selectedIconColor: UIColor? = nil {
        didSet {
            let newColor = self.selectedIconColor ?? self.barTintColor ?? UIColor.white
            self.standardAppearance.stackedLayoutAppearance.selected.iconColor = newColor
            self.standardAppearance.inlineLayoutAppearance.selected.iconColor = newColor
            self.standardAppearance.compactInlineLayoutAppearance.selected.iconColor = newColor
            self.reloadScrollEdgeAppearance()
        }
    }
    
    @IBInspectable var barBackroundColor: UIColor? {
        set {
            self.standardAppearance.backgroundColor = newValue
            self.reloadScrollEdgeAppearance()
        } get {
            return self.standardAppearance.backgroundColor
        }
    }
    
    @IBInspectable var selectionIndicatorTintColor: UIColor? {
        set {
            self.standardAppearance.selectionIndicatorTintColor = newValue
            self.reloadScrollEdgeAppearance()
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
    
    //MARK: - private
    
    private func setupView() {
        
        let appearance = self.standardAppearance
        appearance.backgroundColor = self.barBackroundColor
        if UIDevice.current.userInterfaceIdiom != .tv {
            appearance.inlineLayoutAppearance.normal.titleTextAttributes[NSAttributedString.Key.font] = UIFont.regular(light: 13)
            appearance.inlineLayoutAppearance.selected.titleTextAttributes[NSAttributedString.Key.font] = UIFont.regular(light: 13)
        }
        if #available(iOS 15.0, *) {
            self.scrollEdgeAppearance = appearance
        }
        self.standardAppearance = appearance
    }
    
    private func reloadScrollEdgeAppearance() {
        if #available(iOS 15.0, *) {
            self.scrollEdgeAppearance = self.standardAppearance
        }
    }
    
    var accessoryView: UIView? {
        willSet {
            self.accessoryView?.removeFromSuperview()
        }
        didSet {
            if let accessoryView = self.accessoryView {
                // The action bar is placed as a SIBLING on top of the tab bar (not
                // as a child), and the tab bar's interaction is disabled entirely.
                //
                // Injecting the action bar *into* the tab bar and hiding its buttons
                // did not work: the tab bar nests its buttons below `subviews`, so
                // hiding/hit-testing at this level never reached them and the
                // (invisible) tab buttons kept stealing the taps. Disabling
                // userInteraction on the whole bar disables every nested descendant
                // at once, and the sibling overlay receives the touches itself.
                self.isUserInteractionEnabled = false
                self.subviews.forEach { $0.isHidden = true }
                if let superview = self.superview {
                    accessoryView.frame = self.frame
                    accessoryView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
                    superview.addSubview(accessoryView)
                    superview.bringSubviewToFront(accessoryView)
                } else {
                    accessoryView.frame = self.bounds
                    accessoryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.addSubview(accessoryView)
                }
            } else {
                self.isUserInteractionEnabled = true
                self.subviews.forEach { $0.isHidden = false }
            }
        }
    }

}
