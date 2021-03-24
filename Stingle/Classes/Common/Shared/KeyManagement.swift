import Foundation

class KeyManagement {
	
    static private let crypto = STApplication.shared.crypto
	
	private static var secret:[UInt8]?
	//TODO : maybe KayChain is better place to store the secret
	static public var key: [UInt8]? { get { return KeyManagement.secret } set(newKey) { KeyManagement.secret = newKey } }
	
	static public func importServerPublicKey(pbk: String) {
		guard let pbkData = self.crypto.base64ToByte(encodedStr: pbk) else {
			return
		}
		do {
            try self.crypto.importServerPublicKey(pbk: pbkData)
		} catch {
			print(error)
		}
	}
	
	static public func importKeyBundle(keyBundle:String, password:String) -> Bool {
		guard let keyBundleBytes = self.crypto.base64ToByte(encodedStr: keyBundle) else {
			return false
		}
		do {
			try self.crypto.importKeyBundle(keys: keyBundleBytes, password: password)
		} catch {
			print(error)
			return false
		}
		return true
	}
	
	static public func signOut() {
		KeyManagement.key = nil
		guard let privateFolder = SPFileManager.folder(for: .Private) else {
			print("Can't delete local folder")
			return
		}
		do {
			try SPFileManager.default.removeItem(at: privateFolder)
		} catch {
			print(error)
		}
	}
	
	static public func getUploadKeyBundle(password:String, includePrivateKey:Bool) throws -> String? {
		var keyBundleBytes:[UInt8]? = nil
		do {
			if includePrivateKey {
				keyBundleBytes = try self.crypto.exportKeyBundle(password: password)
			} else {
				keyBundleBytes = try self.crypto.exportPublicKey()
			}
		} catch {
			throw error
		}
		guard let keyBundle = self.crypto.bytesToBase64(data: keyBundleBytes!) else {
			//TODO : throw error
			return nil
		}
		return keyBundle
	}
}
