import Foundation

protocol IResponse: Decodable {
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
