import Foundation

protocol SPResponse : Codable {
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

struct SPUpdateResponse: SPResponse {

	var status:String
	var parts:Parts
	var infos:[String]
	var errors:[String]

	struct Parts : Codable {
		
		var spaceQuota:String
		var spaceUsed:String

		var deletes:[Deleted]
		var files:[SPFile]
		var trash:[SPFile]

		struct Deleted: Codable {
			var date:String
			var file:String
			var type:Int
		}
				
	}
}
