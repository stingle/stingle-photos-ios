//
//  UIViewController+Extension.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/19/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import UIKit
import StingleRoot

extension UIViewController {
    
    func showOkCancelAlert(title: String?, message: String?, ok: (title: String, handler: (() -> Void)?)? = ("ok".localized, nil),  cancel: (title: String, handler: (() -> Void)?)? = ("cancel".localized, nil)) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let ok = ok {
            let okAction = UIAlertAction(title:  ok.title, style: .default) { (_) in
                ok.handler?()
            }
            alert.addAction(okAction)
        }
        
        if let cancel = cancel {
            let cancelAction = UIAlertAction(title:  cancel.title, style: .default) { (_) in
                cancel.handler?()
            }
            alert.addAction(cancelAction)
        }
        self.showDetailViewController(alert, sender: nil)
    }
	
    func showInfoAlert(title: String?, message: String?, ok: String = "ok".localized,  cancel: Bool = false, handler: (() -> Void)? = nil) {
        let okAction = (ok, handler)
        let cancelAction: (title: String, handler: (() -> Void)?)? = cancel ? ("cancel".localized, nil) : nil
        self.showOkCancelAlert(title: title, message: message, ok: okAction, cancel: cancelAction)
	}
	
	func showError(error: IError, handler: (() -> Void)? = nil) {
		self.showInfoAlert(title: error.title, message: error.message, handler: handler)
	}
    
    func showOkCancelTextAlert(title: String?, message: String?, textFieldHandler: ((UITextField) -> Void)? = nil, handler: ((String?) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok".localized, style: .default) {_ in
            handler?(alert.textFields?.first?.text)
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel){_ in
            cancel?()
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        if let textFieldHandler = textFieldHandler {
            alert.addTextField { (textField) in
                textFieldHandler(textField)
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
	
}
