//
//  STValidator.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/19/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

public class STValidator {
    
    public init() {}
	
    @discardableResult public func validate(email: String?) throws -> String {
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
	
    @discardableResult public func validate(password: String?, withCharacters: Bool = true) throws -> String {
		guard let password = password, !password.isEmpty else {
			throw ValidatorError.passwordIsNil
		}
		
		if !withCharacters {
			return password
		}
		
		let isValid = password.trimmingCharacters(in: .whitespaces).count > 5
		if !isValid {
			throw ValidatorError.passwordIncorrect
		}
		return password
	}
    
    public func validate(password: String?, confirmPassword: String?) throws -> String {
        let password = try self.validate(password: password)
        guard  password == confirmPassword else {
            throw ValidatorError.confirmPassword
        }
        return password
    }

    @discardableResult public func validate(string: String?) throws -> String {
        guard let string = string, !string.isEmpty else {
            throw ValidatorError.emptyText
        }
        return string
    }
    
    public func validate(user: STUser?) throws -> Bool {
        try self.validate(email: user?.email)
        try self.validate(string: user?.homeFolder)
        try self.validate(string: user?.token)
        try self.validate(string: user?.userId)
        return true
    }
	
}

extension STValidator {
	
	private enum ValidatorError: IError {
				
		case emailIsNil
		case emailIncorrect
		case passwordIsNil
		case passwordIncorrect
        case emptyText
        case confirmPassword
		
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
            case .emptyText:
                return "error_empty_text".localized
            case .confirmPassword:
                return "error_incorrect_confirm_password".localized
			}
			
		}
		
	}
	
}
