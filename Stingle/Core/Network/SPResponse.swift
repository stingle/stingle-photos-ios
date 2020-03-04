import Foundation

protocol SPResponse : Decodable {
	
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
