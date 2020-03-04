
//This extension is for add functions which are not ported from Clibsodium
import Sodium
import Clibsodium

extension SecretBox {
    
    func seal(message: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
        guard secretKey.count == KeyBytes else { return nil }
        var authenticatedCipherText = Bytes(repeating: 0, count: message.count + MacBytes)

        crypto_secretbox_easy (
            &authenticatedCipherText,
            message, UInt64(message.count),
            nonce,
            secretKey
        )
        return authenticatedCipherText
    }
    
    func exportPublicKey(secretKey:Bytes) -> Bytes? {
        guard secretKey.count == KeyBytes else { return nil }
        var publicKey = Bytes(repeating: 0, count: crypto_box_publickeybytes())
        crypto_scalarmult_base(&publicKey, secretKey)
        return publicKey
    }    
}

extension Data {
    var hexString: String {
		return reduce("") {$0 + String(format: "%02x", $1)}.uppercased()
    }
}

extension String {
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)
		let regex = try! NSRegularExpression(pattern: "[0-9a-fA-F]{1,2}", options: [])
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        guard data.count > 0 else { return nil }
        return data
    }
}
