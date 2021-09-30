//
//  Crypto+PrivateKey.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Foundation
import Sodium
import Clibsodium

extension STCrypto {
    
    func generateMainKeypair(password: String) throws {
        try self.generateMainKeypair(password:password, privateKey: nil, publicKey: nil)
    }
    
    func generateMainKeypair(password: String , privateKey: Bytes?, publicKey: Bytes?) throws {
        guard let pwdSalt: Bytes = self.sodium.randomBytes.buf(length: self.sodium.pwHash.SaltBytes) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        
        _ = try self.savePrivateFile(filename: Constants.PwdSaltFilename, data: pwdSalt)
        
        var privateKey: Bytes?  = privateKey
        var publicKey: Bytes?  = publicKey
        
        if(privateKey == nil || publicKey == nil) {
            guard let keyPair = sodium.box.keyPair() else {
                throw CryptoError.Internal.keyPairGenerationFailure
            }
            privateKey = privateKey ?? keyPair.secretKey
            publicKey = publicKey ?? keyPair.publicKey
        }
        
        let pwdKey = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
        
        guard let pwdEncNonce = self.sodium.randomBytes.buf(length: sodium.secretBox.NonceBytes) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        _ = try self.savePrivateFile(filename: Constants.SKNONCEFilename, data: pwdEncNonce)
        
        let encryptedPrivateKey = try self.encryptSymmetric(key: pwdKey, nonce: pwdEncNonce, data: privateKey)
        
        _ = try self.savePrivateFile(filename: Constants.PrivateKeyFilename, data: encryptedPrivateKey)
        _ = try self.savePrivateFile(filename: Constants.PublicKeyFilename, data: publicKey!)
    }
    
    func getPrivateKey(password: String) throws  -> Bytes {
        let encKey = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
        let encPrivKey = try self.readPrivateFile(fileName: Constants.PrivateKeyFilename)
        let nonce = try self.readPrivateFile(fileName: Constants.SKNONCEFilename)
        let privateKey = try self.decryptSymmetric(key:encKey, nonce:nonce, data: encPrivKey)
        return privateKey
    }
    
    func reencryptPrivateKey(oldPassword: String, newPassword: String) throws {
        let privateKey = try self.getPrivateKey(password: oldPassword)
        let pwdKey = try self.getKeyFromPassword(password: newPassword, difficulty: Constants.KdfDifficultyNormal)
        let pwdEncNonce = try self.readPrivateFile(fileName: Constants.SKNONCEFilename)
        let encryptedPrivateKey = try self.encryptSymmetric(key: pwdKey, nonce: pwdEncNonce, data: privateKey)
        try self.savePrivateFile(filename: Constants.PrivateKeyFilename, data: encryptedPrivateKey)
    }
   
    func getPrivateKeyFromExportedKey(password: String, encPrivKey: Bytes) throws -> Bytes {
        let nonce = try self.readPrivateFile(fileName: Constants.SKNONCEFilename)
        let decPK = try self.decryptSymmetric(key: self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyHard), nonce: nonce, data: encPrivKey)
        return try self.encryptSymmetric(key: self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal), nonce: nonce, data: decPK)
    }
    
    public func getKeyFromPassword(password: String, difficulty: Int) throws -> Bytes {
        let salt = try self.readPrivateFile(fileName: Constants.PwdSaltFilename)
        guard salt.count == self.sodium.pwHash.SaltBytes else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        var opsLimit = self.sodium.pwHash.OpsLimitInteractive
        var memlimit = self.sodium.pwHash.MemLimitInteractive
        
        switch difficulty {
        case Constants.KdfDifficultyHard:
            opsLimit = self.sodium.pwHash.OpsLimitModerate
            memlimit = self.sodium.pwHash.MemLimitModerate
            break
        case Constants.KdfDifficultyUltra:
            opsLimit = self.sodium.pwHash.OpsLimitSensitive
            memlimit = self.sodium.pwHash.MemLimitSensitive
            break
        default:
            break
        }
        
        guard let key = sodium.pwHash.hash(outputLength: self.sodium.secretBox.KeyBytes, passwd: password.bytes, salt: salt, opsLimit: opsLimit, memLimit: memlimit, alg: .Argon2ID13) else {
            throw CryptoError.Internal.hashGenerationFailure
        }
        return key
    }
    
}

extension STCrypto {
    
    func generateSecretKey() -> String? {
        let secretKey = self.sodium.secretBox.key()
        return self.bytesToBase64(data: secretKey)
    }
    
    func encrypted(text: String, for secretKey: String) -> String? {
        let message = text.bytes
        guard let key = self.base64ToByte(encodedStr: secretKey), let encrypted: Bytes = self.sodium.secretBox.seal(message: message, secretKey: key) else {
            return nil
        }
        return self.bytesToBase64(data: encrypted)
    }
    
    func decrypted(text: String, for secretKey: String) -> String? {
        guard let encrypted = self.base64ToByte(encodedStr: text), let key = self.base64ToByte(encodedStr: secretKey), let decrypted = self.sodium.secretBox.open(nonceAndAuthenticatedCipherText: encrypted, secretKey: key) else {
            return nil
        }
        return String(data: Data(decrypted), encoding: .utf8)
    }
    
}
