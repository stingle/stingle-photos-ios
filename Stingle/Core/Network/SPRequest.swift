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
	func params () -> String?
	func path () -> String
	func method () -> SPRequestMethod
	func headers () ->  [String : String]?
	func boundary() -> String?
}

extension SPRequest {
    func boundary() -> String? {
		return "*****" + "\(Date.init().millisecondsSince1970)" + "*****"
	}
}

struct SPPreSignInRequest : SPRequest {

	let email:String
	init(email:String) {
		self.email = email
	}
	func params () -> String? {
		return "email=\(email)"
	}
	func path () -> String {
		return "login/preLogin"
	}
	func method () -> SPRequestMethod {
		return .POST
	}
	func headers() ->  [String : String]? {
		return nil
	}
}

struct SPSignInRequest : SPRequest {
	
	let email:String
	let password:String
	
	init(email:String, password:String) {
		self.email = email
		self.password = password
	}

	func params () -> String? {
		return "email=\(email)&password=\(password)"
	}
	
	func path () -> String {
		return "login/login"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers() ->  [String : String]? {
		return nil
	}
}

struct SPUploadFileRequest : SPRequest {
	
	let token:String
	let fileName:String
	let version:String
	let dateCreated:String
	let dateModified:String
	let fileHeaders:String
	let folder:Int

	init(file:SPFileInfo, folder:Int) {
		token = SPApplication.user!.token
		self.fileName = file.name
		version = file.version
		dateCreated = file.dateCreated
		dateModified = file.dateModified
		fileHeaders = file.headers
		self.folder = folder
	}
	
	func params () -> String? {
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "folder", value: "\(folder)"), URLQueryItem(name: "token", value: token), URLQueryItem(name: "dateCreated", value: dateCreated), URLQueryItem(name: "dateModified", value: dateModified), URLQueryItem(name: "headers", value: fileHeaders), URLQueryItem(name: "version", value: version)]
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func path () -> String {
		return "sync/upload"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers() ->  [String : String]? {
		guard let boundary = boundary() else {
			return nil
		}
		return ["Connection" : "Keep-Alive", "User-Agent" :  "Stingle Photos HTTP Client 1.0", "Content-Type" : "multipart/form-data; boundary=\(boundary)"]
	}
}

struct SPGetUpdateRequest : SPRequest {

	private let token:String
	private let lastSeen:String
	private let lastDelSeenTime:String
	
	init(token:String, lastSeen:String = "0", lastDelSeenTime:String = "0") {
		self.token = token
		self.lastSeen = lastSeen
		self.lastDelSeenTime = lastDelSeenTime
	}

	func params () -> String? {
		//TODO : Make general logic for params creation 
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "lastSeenTime", value: lastSeen), URLQueryItem(name: "lastDelSeenTime", value: lastDelSeenTime), URLQueryItem(name: "token", value: token)]
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func path () -> String {
		return "sync/getUpdates"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}
}

struct SPDownloadFileRequest : SPRequest {
	
	let token:String
	let fileName:String
	let isThumb:Bool
	let folder:Int
	
	init(token:String, fileName:String, isThumb:Bool = false, folder:Int) {
		self.token = token
		self.fileName = fileName
		self.isThumb = isThumb
		self.folder = folder
	}
	
	func path () -> String {
		return "sync/download"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}

	func params () -> String? {
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "folder", value: "\(folder)"),URLQueryItem(name: "file", value: fileName), URLQueryItem(name: "token", value: token)]
		if isThumb {
			components.queryItems?.append(URLQueryItem(name: "thumb", value: "1"))
		}
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
}
