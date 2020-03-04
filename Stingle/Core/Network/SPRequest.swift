import Foundation

enum SPRequestMethod : String {
	case POST
	case GET
	case NOTIMPLEMENTED
	
	func value() -> String {
		return self.rawValue
	}
	
}

protocol SPRequest {
	func params () -> String
	func path () -> String
	func method () -> SPRequestMethod
}

struct SPPreSignInRequest : SPRequest {

	let email:String

	func params () -> String {
		return "email=\(email)"
	}
	
	func path () -> String {
		return "login/preLogin"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	init(email:String) {
		self.email = email
	}
}

struct SPSignInRequest : SPRequest {
	
	let email:String
	let password:String
	
	init(email:String, password:String) {
		self.email = email
		self.password = password
	}

	func params () -> String {
		return "email=\(email)&password=\(password)"
	}
	
	func path () -> String {
		return "login/login"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
}

