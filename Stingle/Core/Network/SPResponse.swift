import Foundation

protocol SPResponse : Codable {
}

struct SPDefaultResponse: SPResponse {
	
	var status:String
	var parts:[String]
	var infos:[String]
	var errors:[String]
}

struct SPTrashResponse: SPResponse {
	
	var status:String
	var parts:[String]
	var infos:[String]
	var errors:[String]
	
	struct ServerPart : Codable {
		var server_data:String
		var server_nonce:String
		var server_genKey:String
	}
}


struct SPSignUpResponse: SPResponse {
	
	var status:String
	var parts:SignUpPart
	var infos:[String]
	var errors:[String]
	
	struct SignUpPart : Codable {
		var homeFolder:String
		var token:String
		var userId:String
	}
}


struct SPPreSignInResponse: SPResponse {
	
	var status:String
	var parts:PreSignInPart
	var infos:[String]
	var errors:[String]
	
	struct PreSignInPart : Codable {
		var salt:String
	}
}

struct SPSignInResponse: SPResponse {
	
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

struct SPSignOutResponse: SPResponse {
	var status:String
	var parts:[String]
	var infos:[String]
	var errors:[String]
}


struct SPUpdateInfo: SPResponse {

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
