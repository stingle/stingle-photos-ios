//
//  STValidator.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/19/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

class STValidator {
	
	func validate(email: String?) throws -> String {
		guard let email = email, !email.isEmpty else {
			throw ValidatorError.emailIsNil
		}
		let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
		let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
		let isValid = pred.evaluate(with: email.trimmingCharacters(in: .whitespaces))
		if !isValid {
			throw ValidatorError.emailIncorrect
		}
		return email
	}
	
	
	func validate(password: String?) throws -> String {
		guard let password = password, !password.isEmpty else {
			throw ValidatorError.passwordIsNil
		}
		let isValid = password.trimmingCharacters(in: .whitespaces).count > 4
		if !isValid {
			throw ValidatorError.passwordIncorrect
		}
		return password
	}
	
}

extension STValidator {
	
	private enum ValidatorError: IError {
				
		case emailIsNil
		case emailIncorrect
		case passwordIsNil
		case passwordIncorrect
		
		var message: String {
		
			switch self {
			case .emailIsNil:
				return "error_empty_email".localized
			case .emailIncorrect:
				return "error_incorrect_email".localized
			case .passwordIsNil:
				return "error_empty_password".localized
			case .passwordIncorrect:
				return "error_incorrect_password".localized
			}
			
		}
		
	}
	
}
