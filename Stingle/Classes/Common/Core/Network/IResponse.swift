import Foundation

protocol IResponse: Codable {
}

class STResponse<T: Codable>: IResponse {
	
	private enum CodingKeys: String, CodingKey {
		case status = "status"
		case parts = "parts"
		case infos = "infos"
		case errors = "errors"
	}
	
	var status: String
	var parts: T?
	var infos: [String]
	var errors: [String]
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.status = try container.decode(String.self, forKey: .status)
		self.parts = try? container.decodeIfPresent(T.self, forKey: .parts)
		self.infos = try container.decode([String].self, forKey: .infos)
		self.errors = try container.decode([String].self, forKey: .errors)
	}
}

struct SPDefaultResponse: IResponse {
	
	var status:String
	var parts:[String]
	var infos:[String]
	var errors:[String]
}

struct SPTrashResponse: IResponse {
	
	var status:String
	var parts:[[String:String]]
	var infos:[String]
	var errors:[String]	
}

class SPSignUpResponse: STResponse<SPSignUpResponse.SignUpPart> {
	
	struct SignUpPart: Codable {
		var homeFolder: String
		var token: String
		var userId: String
	}
}


struct SPPreSignInResponse: IResponse {
	
	var status:String
	var parts:PreSignInPart
	var infos:[String]
	var errors:[String]
	
	struct PreSignInPart : Codable {
		var salt:String
	}
}

struct SPSignInResponse: IResponse {
	
	var status:String
	var parts:SignInPart
	var infos:[String]
	var errors:[String]
	
	struct SignInPart : Codable {
		var homeFolder:String
		var isKeyBackedUp:Int
		var keyBundle:String
		var serverPublicKey:String
		var token:String
		var userId:String
	}
}

struct SPSignOutResponse: IResponse {
	var status:String
	var parts:[String]
	var infos:[String]
	var errors:[String]
}


struct SPUpdateInfo: IResponse {

	var status:String
	var parts:Parts
	var infos:[String]
	var errors:[String]

	struct Parts : Codable {
		
		var spaceQuota:String
		var spaceUsed:String

		var deletes:[SPDeletedFile]
		var files:[SPFile]
		var trash:[SPTrashFile]
	}
}

struct SPUploadResponse: IResponse {

	var status:String
	var parts:Parts
	var infos:[String]
	var errors:[String]

	struct Parts : Codable {
		var spaceQuota:String
		var spaceUsed:String
	}
}

struct SPGetFileUrlResponse: IResponse {
	var status:String
	var parts:Parts
	var infos:[String]
	var errors:[String]
	
	struct Parts : Codable {
		var url:URL
	}
}
