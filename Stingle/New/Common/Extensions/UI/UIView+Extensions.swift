//
//  UIView+Extensions.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/19/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

extension UIView {
	
	@discardableResult
	func addSubviewFullContent(view: UIView, inserIndex: Int? = nil, top: CGFloat? = 0, right: CGFloat? = 0, left: CGFloat? = 0, bottom: CGFloat? = 0) -> (NSLayoutConstraint?, NSLayoutConstraint?, NSLayoutConstraint?, NSLayoutConstraint?) {
		
		if let inserIndex = inserIndex {
			self.insertSubview(view, at: inserIndex)
		} else {
			self.addSubview(view)
		}
		
		view.translatesAutoresizingMaskIntoConstraints = false
		view.frame = self.bounds
		
		var constraints = [NSLayoutConstraint]()
		
		
		var topConstraint: NSLayoutConstraint?
		if let top = top {
			let constraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: top)
			topConstraint = constraint
			constraints.append(constraint)
		}
		
		var rightConstraint: NSLayoutConstraint?
		if let right = right {
			let constraint = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -right)
			rightConstraint = constraint
			constraints.append(constraint)
		}
		
		var leftConstraint: NSLayoutConstraint?
		if let left = left {
			let constraint = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: left)
			leftConstraint = constraint
			constraints.append(constraint)
		}
		
		var bottomConstraint: NSLayoutConstraint?
		if let bottom = bottom {
			let constraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -bottom)
			bottomConstraint = constraint
			constraints.append(constraint)
		}
		
		self.addConstraints(constraints)
		return (topConstraint, rightConstraint, bottomConstraint, leftConstraint)
	}
	
}
