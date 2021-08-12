//
//  STMnemonic.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/12/21.
//

import Foundation
import Security
import CryptoSwift

struct STMnemonic {
    
    func mnemonicString(from bytes: [UInt8]) -> String? {
        let hex = bytes.toHexString()
        return self.mnemonicString(from: hex)
    }
    
    func mnemonicString(from hexString: String) -> String? {
        
        let seedData = self.mnemonicData(string: hexString)
        let hashData = seedData.sha256()
        let checkSum = self.toBitArray(data: hashData)
        var seedBits = self.toBitArray(data: seedData)
        
        for i in 0 ..< seedBits.count / 32 {
            seedBits.append(checkSum[i])
        }
        
        let words = self.words
        
        let mnemonicCount = seedBits.count / 11
        var mnemonic = [String]()
        for i in 0 ..< mnemonicCount {
            let length = 11
            let startIndex = i * length
            let subArray = seedBits[startIndex ..< startIndex + length]
            let subString = subArray.joined(separator: "")
            
            let index = Int(strtoul(subString, nil, 2))
            mnemonic.append(words[index])
        }
        return mnemonic.joined(separator: " ")
    }
    
    func deterministicSeedBytes(from mnemonic: String, iterations: Int = 2_048, passphrase: String = "") -> [UInt8]? {
        guard self.validate(mnemonic: mnemonic),
              let normalizedData = self.normalized(string: mnemonic),
              let saltData = normalized(string: "mnemonic" + passphrase) else {
            return nil
        }
        
        let passwordBytes = normalizedData.bytes
        let saltBytes = saltData.bytes
        do {
            let bytes = try PKCS5.PBKDF2(password: passwordBytes, salt: saltBytes, iterations: iterations, variant: .sha512).calculate()
            
            return bytes
        } catch {
            return nil
        }
    }
    
    func deterministicSeedString(from mnemonic: String, iterations: Int = 2_048, passphrase: String = "") -> String? {
        let bytes = self.deterministicSeedBytes(from: mnemonic, iterations: iterations, passphrase: passphrase)
        return bytes?.toHexString()
    }
    
    func generateMnemonic(strength: Int) -> String? {
        
        guard strength % 32 == 0 else {
            return nil
        }
        
        // Securely generate random bytes.
        // See: https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
        let count = strength / 8
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            return nil
        }
        
        let hexString = bytes.toHexString()
        return self.mnemonicString(from: hexString)
    }
    
    func validate(mnemonic: String) -> Bool {
        let normalizedMnemonic = mnemonic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let mnemonicComponents = normalizedMnemonic.components(separatedBy: " ")
        guard !mnemonicComponents.isEmpty else {
            return false
        }
        
        let words = self.words
        
        if words.contains(mnemonicComponents[0]) {
            for mnemonicComponent in mnemonicComponents {
                guard words.contains(mnemonicComponent) else {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }
    
    private func normalized(string: String) -> Data? {
        guard let data = string.data(using: .utf8, allowLossyConversion: true),
              let dataString = String(data: data, encoding: .utf8),
              let normalizedData = dataString.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }
        return normalizedData
    }
}
