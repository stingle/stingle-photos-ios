import Foundation

class KeyManagement {
	
	static private let crypto = Crypto()
	
	private static var secret:[UInt8] = []
	//TODO : maybe KayChain is better place to store the secret
	static public var key:[UInt8] { get { return KeyManagement.secret } set(newKey) { KeyManagement.secret = newKey } }
	
	static public func importServerPublicKey(pbk:String) {
		guard let pbkData = crypto.base64ToByte(data: pbk) else {
			
			return
		}
		do {
			try crypto.importServerPublicKey(pbk: pbkData)
		} catch {
			print(error)
		}
	}
	
	static public func importKeyBundle(keyBundle:String, password:String) -> Bool {
		guard let keyBundleBytes = SPApplication.crypto.base64ToByte(data: keyBundle) else {
			return false
		}
		do {
			try SPApplication.crypto.importKeyBundle(keys: keyBundleBytes, password: password)
		} catch {
			print(error)
			return false
		}
		return true
	}
	
	static public func getUploadKeyBundle(password:String, includePrivateKey:Bool) throws -> String? {
		var keyBundleBytes:[UInt8]? = nil
		do {
			if includePrivateKey {
				keyBundleBytes = try crypto.exportKeyBundle(password: password)
			} else {
				keyBundleBytes = try crypto.exportPublicKey()
			}
		} catch {
			throw error
		}
		guard let keyBundle = crypto.bytesToBase64(data: keyBundleBytes!) else {
			//TODO : throw error
			return nil
		}
		return keyBundle
	}
}
