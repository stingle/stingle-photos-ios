
import Foundation

class Utils {
	
	public static func getNewEncFilename() -> String? {
        let crypto:Crypto = STApplication.shared.crypto
		guard let randData = crypto.getRandomBytes(lenght: Constants.FileNameLen) else {
			return nil
		}
		
		let base64Str = crypto.bytesToBase64(data: randData)
		return base64Str?.appending(Constants.FileExtension)
	}
	
	public func createAndSaveThumb(file:SPFile) -> Bool {
		
		return false
	}
}
