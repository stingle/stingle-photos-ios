//
//  STStatusBar.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/27/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

class STStatusBar: UIView {
	
	@discardableResult
	init(for window: UIWindow? = UIApplication.shared.windows.first) {
		let window = window ?? UIApplication.shared.windows.first
		super.init(frame: .zero)
		window?.addSubview(self)
		self.backgroundColor = Theme.Colors.SPDarkRed
		self.frame = self.getFrame()
		self.autoresizingMask = [.flexibleWidth]
		self.layer.zPosition = 1200
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func getFrame() -> CGRect {
		let window = self.window ?? UIApplication.shared.windows.first
		let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
		return statusBarFrame
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.frame = self.getFrame()
	}
	
	
	
}
