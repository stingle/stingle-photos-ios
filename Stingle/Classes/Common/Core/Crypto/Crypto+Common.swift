//
//  File.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Sodium
import Clibsodium

extension Crypto {
    
    public func chunkAdditionalSize  () -> Int {
        return self.sodium.aead.xchacha20poly1305ietf.ABytes + sodium.aead.xchacha20poly1305ietf.NonceBytes
    }
    
    public func getRandomBytes(lenght:Int) -> Bytes? {
        return self.sodium.randomBytes.buf(length: lenght)
    }
    
    public func newFileId() -> Bytes? {
        return self.getRandomBytes(lenght: Constants.FileFileIdLen)
    }
    
    public static func toBytes<T: FixedWidthInteger>(value: T) -> Bytes {
        let array = withUnsafeBytes(of: value.bigEndian, Array.init)
        return array
    }
    
    public static func fromBytes<T: FixedWidthInteger>(b:Bytes) -> T  {
        assert(0 != b.count)
        if b.count == 1 {
            return T(b[0] & 255)
        }
        
        var result:T = T(0)
        var shift = 0
        for index in (0...b.count - 1) {
            shift = 8 * (b.count - 1 - index)
            result |= T(b[index] & 255) << shift
        }
        return result
    }
    
    //ENCODE
    public func bytesToBase64(data: Bytes) -> String? {
         return Data(data).base64EncodedString()
    }
    
    //DECODE
    public func base64ToByte(encodedStr: String) -> Bytes? {
        guard let decodedData = Data(base64Encoded: encodedStr, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return Bytes(decodedData)
    }
    
    func base64urlToBase64(base64urlString: String) -> String {
        var base64 = base64urlString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    func toBytes(header: STHeader) -> Bytes {
        
        // Current header version - 1 byte
        var headerBytes = [UInt8(header.headerVersion & 255)]
        
        // Chunk size - 4 bytes
        headerBytes += Crypto.toBytes(value: header.chunkSize)
        
        // Data size - 8 bytes
        headerBytes += Crypto.toBytes(value:header.dataSize)
        
        // Symmentric key - 32 bytes
        headerBytes += header.symmetricKey
        
        // File type - 1 byte
        headerBytes += [UInt8(header.fileType & 255)]
        
        let name = header.fileName ?? ""
        if name != "" {
            let bytes:Bytes = name.bytes
            headerBytes += Crypto.toBytes(value: UInt32(bytes.count))
            headerBytes += bytes
        } else {
            headerBytes += Crypto.toBytes(value: Int(0))
        }
        
        headerBytes += Crypto.toBytes(value: header.videoDuration)
        return headerBytes
    }
    
    
    public func encryptCryptoBox(message: Bytes, publicKey: Bytes, privateKey: Bytes) throws  -> Bytes? {
        guard let nonce = self.getRandomBytes(lenght: self.sodium.box.NonceBytes) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        guard let result:Bytes = self.sodium.box.seal(message: message, recipientPublicKey: publicKey, senderSecretKey: privateKey, nonce: nonce) else {
            return nil
        }
        return nonce + result
    }

    func encryptParamsForServer(params: [String:String]) -> String? {
        do {
            let spbk  = try self.getServerPublicKey()
            guard let pks = KeyManagement.key else {
                throw CryptoError.Bundle.pivateKeyIsEmpty
            }
            let json = try JSONSerialization.data(withJSONObject: params)
            guard let res  = try self.encryptCryptoBox(message: (Bytes)(json), publicKey: spbk, privateKey: pks) else {
                return nil
            }
            return self.bytesToBase64(data: res)
        } catch {
            return nil
        }
    }
}
