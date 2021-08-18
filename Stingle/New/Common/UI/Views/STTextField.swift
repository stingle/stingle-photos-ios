//
//  STTextField.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/17/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

@IBDesignable class STTextField: UITextField {

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
	
	override func becomeFirstResponder() -> Bool {
		self.isKeyboardVisible = true
		self.setNeedsDisplay()
		return super.becomeFirstResponder()
	}
   
	override func resignFirstResponder() -> Bool {
		self.isKeyboardVisible = false
		self.setNeedsDisplay()
		return super.resignFirstResponder()
	}
	
    override func draw(_ rect: CGRect) {
		super.draw(rect)
		let color = (self.isKeyboardVisible ? self.selectedUnderlineColor : self.underlineColor) ?? self.underlineColor
		guard let context = UIGraphicsGetCurrentContext(), let drawColor = color else {
			return
		}
        let rect = CGRect(x: 0, y: rect.height - self.underlineHeight + rect.origin.y, width: rect.width, height: self.underlineHeight)
		let path = CGPath(roundedRect: rect, cornerWidth: 0.5, cornerHeight: 0.5, transform: nil)
		context.addPath(path)
		context.setFillColor(drawColor.cgColor)
		context.fillPath()
    }

}
