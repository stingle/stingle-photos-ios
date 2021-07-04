//
//  UIViewController+Extension.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/19/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit

extension UIViewController {
	
    func showInfoAlert(title: String?, message: String?, cancel: Bool = false, handler: (() -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title:  "ok".localized, style: .default) { (_) in
			handler?()
		}
		alert.addAction(okAction)
        
        if cancel {
            let cancel = UIAlertAction(title:  "cancel".localized, style: .cancel)
            alert.addAction(cancel)
        }
        
		self.present(alert, animated: true)
	}
	
	func showError(error: IError, handler: (() -> Void)? = nil) {
		self.showInfoAlert(title: error.title, message: error.message, handler: handler)
	}
    
    func showOkCancelAlert(title: String?, message: String?, textFieldText: String? = nil, textFieldPlaceholder: String? = nil, handler: @escaping ((String?) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok".localized, style: .default) {_ in
            handler(alert.textFields?.first?.text)
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        
        if let textFieldPlaceholder = textFieldPlaceholder {
            alert.addTextField { (textField) in
                textField.text = textFieldText
                textField.placeholder = textFieldPlaceholder
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
	
}
