import Foundation

enum SPRequestMethod : String {
	case POST
	case GET
	case NOTIMPLEMENTED
	
	func value() -> String {
		return self.rawValue
	}
}

let crypto:Crypto  = Crypto()


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
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "email", value: "\(email)")]
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
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
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "email", value: "\(email)"),URLQueryItem(name: "password", value: password)]
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
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

struct SPSignUpRequest : SPRequest {
	
	let email:String
	let password:String
	let salt:String
	let isBackup:Bool
	let keyBundle:String
	
	init(email:String, password:String, salt:String, keyBundle:String, isBackup:Bool) {
		self.email = email
		self.password = password
		self.salt = salt
		self.keyBundle = keyBundle
		self.isBackup = isBackup
	}

	func params () -> String? {
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "email", value: "\(email)"),URLQueryItem(name: "password", value: password), URLQueryItem(name: "salt", value: salt), URLQueryItem(name: "keyBundle", value: keyBundle)]
		if isBackup {
			components.queryItems?.append(URLQueryItem(name: "isBackup", value: "1"))
		} else {
			components.queryItems?.append(URLQueryItem(name: "isBackup", value: "0"))
		}
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func path () -> String {
		return "register/createAccount"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers() ->  [String : String]? {
		return nil
	}
}

struct SPSignOutRequest : SPRequest {
	
	let token:String
	
	init(token:String) {
		self.token = token
	}

	func params () -> String? {
		var components = URLComponents()
		components.queryItems = [URLQueryItem(name: "token", value: "\(token)")]
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func path () -> String {
		return "login/logout"
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
		} else {
			components.queryItems?.append(URLQueryItem(name: "thumb", value: "0"))
		}
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
}

struct SPMoveFilesRequest : SPRequest {
	let token:String
	let to:Int
	let from:Int
	let isMoving:Bool
	let files:[SPFileInfo]
	
	init(token:String, to:Int, from:Int, files:[SPFileInfo], isMoving:Bool) {
		self.token = token
		self.to = to
		self.from = from
		self.files = files
		self.isMoving = isMoving
	}
	
	func path () -> String {
		return "sync/moveFile"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}

	func params () -> String? {
		var params = [String:String?]()
		params["setTo"] = "\(to)"
		params["setFrom"] = "\(from)"
		params["albumIdFrom"] = nil
		params["albumIdTo"] = nil
		params["isMoving"] = "\( isMoving ? 1 : 0)"
		params["count"] = "\(files.count)"
		var index = 0
		for file in files {
			params["filename\(index)"] = file.name
			index += 1
		}
		return nil
	}
}

struct SPTrashFilesRequest : SPRequest {
	let token:String
	let files:[SPFileInfo]
	
	init(token:String, files:[SPFileInfo]) {
		self.token = token
		self.files = files
	}
	
	func path () -> String {
		return "sync/trash"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}

	func params() -> String? {
		var components = URLComponents()
		//TODO : Remove v : 16
		components.queryItems = [URLQueryItem(name: "token", value: token), URLQueryItem(name: "params", value: bodyParams())]
		components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func bodyParams () -> String {
		var params = [String:String]()
		params["count"] = "\(files.count)"
		var index = 0
		for file in files {
			params["filename\(index)"] = file.name
			index += 1
		}
		guard let encParams = crypto.encryptParamsForServer(params: params) else {
			return ""
		}
		return encParams
	}
}


struct SPRestoreFilesRequest : SPRequest {
	let token:String
	let files:[SPFileInfo]
	
	init(token:String, files:[SPFileInfo]) {
		self.token = token
		self.files = files
	}
	
	func path () -> String {
		return "sync/restore"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}

	func params() -> String? {
		var components = URLComponents()
		//TODO : Remove v : 16
		components.queryItems = [URLQueryItem(name: "token", value: token), URLQueryItem(name: "params", value: bodyParams())]
		components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func bodyParams () -> String {
		var params = [String:String]()
		params["count"] = "\(files.count)"
		var index = 0
		for file in files {
			params["filename\(index)"] = file.name
			index += 1
		}
		guard let encParams = crypto.encryptParamsForServer(params: params) else {
			return ""
		}
		return encParams
	}
}


struct SPDeleteFilesRequest : SPRequest {
	let token:String
	let files:[SPFileInfo]
	
	init(token:String, files:[SPFileInfo]) {
		self.token = token
		self.files = files
	}
	
	func path () -> String {
		return "sync/delete"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}

	func params() -> String? {
		var components = URLComponents()
		//TODO : Remove v : 16
		components.queryItems = [URLQueryItem(name: "token", value: token), URLQueryItem(name: "params", value: bodyParams())]
		components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func bodyParams () -> String {
		var params = [String:String]()
		params["count"] = "\(files.count)"
		var index = 0
		for file in files {
			params["filename\(index)"] = file.name
			index += 1
		}
		guard let encParams = crypto.encryptParamsForServer(params: params) else {
			return ""
		}
		return encParams
	}
}


struct SPEmptyTrashRequest : SPRequest {
	let token:String
	
	init(token:String) {
		self.token = token
	}
	
	func path () -> String {
		return "sync/emptyTrash"
	}
	
	func method () -> SPRequestMethod {
		return .POST
	}
	
	func headers () ->  [String : String]? {
		return nil
	}

	func params() -> String? {
		var components = URLComponents()
		//TODO : Remove v : 16
		components.queryItems = [URLQueryItem(name: "token", value: token), URLQueryItem(name: "params", value: bodyParams())]
		components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
		let strParams = components.url?.absoluteString
		return String((strParams?.dropFirst())!)
	}
	
	func bodyParams () -> String {
		var params = [String:String]()
		params["time"] = "\(Date.init().millisecondsSince1970)"
		guard let encParams = crypto.encryptParamsForServer(params: params) else {
			return ""
		}
		return encParams
	}
}

