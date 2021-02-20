//
//  UIViewController+Extension.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/19/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

extension UIViewController {
	
	func showInfoAlert(title: String?, message: String?, handler: (() -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title:  "ok".localized, style: .default) { (_) in
			handler?()
		}
		alert.addAction(okAction)
		self.present(alert, animated: true)
	}
	
	func showError(error: IError, handler: (() -> Void)? = nil) {
		self.showInfoAlert(title: error.title, message: error.message, handler: handler)
	}
	
}
