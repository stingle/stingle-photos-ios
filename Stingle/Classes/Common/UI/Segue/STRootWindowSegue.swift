//
//  STRootWindowSegue.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/21/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

class STRootWindowSegue: UIStoryboardSegue {
	
	override func perform () {
		
		let src = self.source
		let dst = self.destination
		
		guard let window = src.view.window else {
			return
		}
		
		window.rootViewController = dst
		
		if UIView.areAnimationsEnabled {
			let options: UIView.AnimationOptions = .transitionFlipFromRight
			let duration: TimeInterval = 0.5
			UIView.transition(with: window, duration: duration, options: options, animations: {
			}, completion:
			{ completed in
			})
		}
	}
	
}
