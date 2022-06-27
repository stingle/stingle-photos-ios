// Copyright Keefer Taylor, 2018
// Copyright Electric Coin Company, 2020
import CryptoKit
import Foundation
import Security
import CommonCrypto

enum STMnemonic {
    
    static func mnemonicString(from bytes: [UInt8], language: MnemonicLanguageType = .english) throws -> String {
        let result = try self.mnemonicString(from: bytes.hexString, language: language)
        return result
    }
    
    /// Generate a mnemonic from the given hex string in the given language.
    ///
    /// - Parameters:
    ///   - hexString: The hex string to generate a mnemonic from.
    ///   - language: The language to use. Default is english.
    /// - Returns: the mnemonic string or nil if input is invalid
    /// - Throws:
    ///   - `MnemonicError.InvalidHexString`:  when an invalid string is given
    ///   - `MnemonicError.invalidBitString` when the resulting bitstring generates an invalid word index
    static func mnemonicString(from hexString: String, language: MnemonicLanguageType = .english) throws -> String {
        guard let seedData = hexString.mnemonicData() else { throw MnemonicError.invalidHexstring }
        
        let hashData = SHA256.hash(data: seedData)
        let checkSum = hashData.bytes.toBitArray()
        var seedBits = seedData.toBitArray()

        for i in 0 ..< seedBits.count / 32 {
            seedBits.append(checkSum[i])
        }

        let words = language.words()

        let mnemonicCount = seedBits.count / 11
        var mnemonic = [String]()
        for i in 0 ..< mnemonicCount {
            let length = 11
            let startIndex = i * length
            let subArray = seedBits[startIndex ..< startIndex + length]
            let subString = subArray.joined(separator: "")

            guard let index = Int(subString, radix: 2) else {
                throw MnemonicError.invalidBitString
            }
            mnemonic.append(words[index])
        }
        return mnemonic.joined(separator: " ")
    }

    /// Generate a deterministic seed string from a Mnemonic String.
    ///
    /// - Parameters:
    ///   - mnemonic: The mnemonic to use.
    ///   - iterations: The iterations to perform in the PBKDF2 algorithm. Default is 2048.
    ///   - passphrase: An optional passphrase. Default is the empty string.
    ///   - language: The language to use. Default is english.
    /// - Returns: hexString representing the deterministic seed bytes
    /// - Throws: `MnemonicError.checksumError` if checksum fails, `MnemonicError.invalidInput` if received input is invalid
    static func deterministicSeedString(from mnemonic: String, iterations: Int = 2_048, passphrase: String = "", language: MnemonicLanguageType = .english) throws -> String {
        try deterministicSeedBytes(from: mnemonic, iterations: iterations, passphrase: passphrase, language: language).hexString
    }

    /// Generate a deterministic seed bytes from a Mnemonic String.
    ///
    /// - Parameters:
    ///   - mnemonic: The mnemonic to use.
    ///   - iterations: The iterations to perform in the PBKDF2 algorithm. Default is 2048.
    ///   - passphrase: An optional passphrase. Default is the empty string.
    ///   - language: The language to use. Default is english.
    /// - Returns: a byte array representing the deterministic seed bytes
    /// - Throws: `MnemonicError.checksumError` if checksum fails, `MnemonicError.invalidInput` if received input is invalid
    static func deterministicSeedBytes(from mnemonic: String,  iterations: Int = 2_048, passphrase: String = "", language: MnemonicLanguageType = .english) throws -> [UInt8] {
        
        let normalizedMnemonic = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)

        try self.validate(mnemonic: normalizedMnemonic)

        let normalizedData = try self.normalizedString(normalizedMnemonic)
        let saltData = try self.normalizedString("mnemonic" + passphrase)
        let passwordBytes = normalizedData.map { Int8(bitPattern: $0) }

        do {
            let bytes = try PKCS5.PBKDF2SHA512(password: passwordBytes, salt: [UInt8](saltData), iterations: iterations)
            return bytes
        } catch {
            throw MnemonicError.invalidInput
        }
    }

    /// Generate a mnemonic of the given strength and given language.
    ///
    /// - Parameters:
    ///   - strength: The strength to use. This must be a multiple of 32.
    ///   - language: The language to use. Default is english.
    /// - Returns: the random mnemonic phrase of the given strenght and language or `nil` if the strength is invalid or an error occurs
    /// - Throws:
    ///  - `MnemonicError.InvalidInput` if stregth is invalid in the terms of BIP-39
    ///  - `MnemonicError.entropyCreationFailed` if random bytes created for entropy fails
    ///  - `MnemonicError.InvalidHexString`  when an invalid string is given
    ///  - `MnemonicError.invalidBitString` when the resulting bitstring generates an invalid word index
    static func generateMnemonic(strength: Int, language: MnemonicLanguageType = .english) throws
        -> String {
            guard strength % 32 == 0 else {
                throw MnemonicError.invalidInput
            }

            let count = strength / 8
            var bytes = [UInt8](repeating: 0, count: count)

            guard SecRandomCopyBytes(kSecRandomDefault, count, &bytes) == errSecSuccess else {
                throw MnemonicError.entropyCreationFailed
            }

            return try mnemonicString(from: bytes.hexString, language: language)
    }

    /// Validate that the given string is a valid mnemonic phrase according to BIP-39
    /// - Parameters:
    ///  - mnemonic: a mnemonic phrase string
    /// - Throws:
    ///  - `MnemonicError.wrongWordCount` if the word count is invalid
    ///  - `MnemonicError.invalidWord(word: word)` this phase as a word that's not represented in this library's vocabulary for the detected language.
    ///  - `MnemonicError.unsupportedLanguage` if the given phrase language isn't supported or couldn't be infered
    ///  - `throw MnemonicError.checksumError` if the given phrase has an invalid checksum
    static func validate(mnemonic: String) throws {
        let mnemonicComponents = mnemonic.components(separatedBy: " ")
        guard !mnemonicComponents.isEmpty else {
            throw MnemonicError.wrongWordCount
        }

        guard let wordCount = WordCount(rawValue: mnemonicComponents.count) else {
            throw MnemonicError.wrongWordCount
        }

        // determine the language of the seed or fail
        let language = try determineLanguage(from: mnemonicComponents)
        let vocabulary = language.words()

        // generate indices array
        var seedBits = ""
        for word in mnemonicComponents {
            guard let indexInVocabulary = vocabulary.firstIndex(of: word) else {
                throw MnemonicError.invalidWord(word: word)
            }

            let binaryString = String(indexInVocabulary, radix: 2).pad(toSize: 11)

            seedBits.append(contentsOf: binaryString)
        }

        let checksumLength = mnemonicComponents.count / 3

        guard checksumLength == wordCount.checksumLength else {
                throw MnemonicError.checksumError
        }

        let dataBitsLength = seedBits.count - checksumLength

        let dataBits = String(seedBits.prefix(dataBitsLength))
        let checksumBits = String(seedBits.suffix(checksumLength))

        guard let dataBytes = dataBits.bitStringToBytes() else {
            throw MnemonicError.checksumError
        }

        let hash = SHA256.hash(data: dataBytes)
        let hashBits = hash.bytes.toBitArray().joined(separator: "").prefix(checksumLength)

        guard hashBits == checksumBits else {
            throw MnemonicError.checksumError
        }

    }
    
    static func bytes(mnemonic: String) throws -> [UInt8] {
        let mnemonicComponents = mnemonic.components(separatedBy: " ")
        guard !mnemonicComponents.isEmpty else {
            throw MnemonicError.wrongWordCount
        }
        
        guard let wordCount = WordCount(rawValue: mnemonicComponents.count) else {
            throw MnemonicError.wrongWordCount
        }
        
        // determine the language of the seed or fail
        let language = try determineLanguage(from: mnemonicComponents)
        let vocabulary = language.words()
        
        // generate indices array
        var seedBits = ""
        for word in mnemonicComponents {
            guard let indexInVocabulary = vocabulary.firstIndex(of: word) else {
                throw MnemonicError.invalidWord(word: word)
            }
            
            let binaryString = String(indexInVocabulary, radix: 2).pad(toSize: 11)
            seedBits.append(contentsOf: binaryString)
        }
        
        let checksumLength = mnemonicComponents.count / 3
        guard checksumLength == wordCount.checksumLength else {
            throw MnemonicError.checksumError
        }
        
        let dataBitsLength = seedBits.count - checksumLength
        
        let dataBits = String(seedBits.prefix(dataBitsLength))
        let checksumBits = String(seedBits.suffix(checksumLength))
        
        guard let dataBytes = dataBits.bitStringToBytes() else {
            throw MnemonicError.checksumError
        }
        
        let hash = SHA256.hash(data: dataBytes)
        let hashBits = hash.bytes.toBitArray().joined(separator: "").prefix(checksumLength)
        
        guard hashBits == checksumBits else {
            throw MnemonicError.checksumError
        }
        
        return [UInt8](dataBytes)
    }

    static func determineLanguage(from mnemonicWords: [String]) throws -> MnemonicLanguageType {
        guard mnemonicWords.count > 0 else {
            throw MnemonicError.wrongWordCount
        }

        if MnemonicLanguageType.englishMnemonics.contains(mnemonicWords[0]) {
            return .english
        } else if MnemonicLanguageType.chineseMnemonics.contains(mnemonicWords[0]) {
            return .chinese
        } else {
            throw MnemonicError.unsupportedLanguage
        }
    }

    /// Change a string into data.
    /// - Parameter string: the string to convert
    /// - Returns: the utf8 encoded data
    /// - Throws: `MnemonicError.invalidInput` if the given String cannot be converted to Data
    static func normalizedString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8, allowLossyConversion: true),
            let dataString = String(data: data, encoding: .utf8),
            let normalizedData = dataString.data(using: .utf8, allowLossyConversion: false) else {
                throw MnemonicError.invalidInput
        }
        return normalizedData
    }
}

extension STMnemonic {
    
    enum MnemonicLanguageType {
        
        case english
        case chinese

        func words() -> [String] {
            switch self {
            case .english:
                return Self.englishMnemonics
            case .chinese:
                return Self.chineseMnemonics
            }
        }
    }
    
    enum MnemonicError: IError {
        
       case wrongWordCount
       case checksumError
       case invalidWord(word: String)
       case unsupportedLanguage
       case invalidHexstring
       case invalidBitString
       case invalidInput
       case entropyCreationFailed
        
        var message: String {
            switch self {
            case .wrongWordCount, .invalidWord, .checksumError:
                return "error_incorrect_phrase".localized
            default:
                return "error_unknown_error".localized
            }
        }
   }
    
}

fileprivate extension PKCS5 {
    
    static func PBKDF2SHA512(password: String, salt: String, iterations: Int = 2_048, keyLength: Int = 64) throws -> Array<UInt8> {
        let saltData = try STMnemonic.normalizedString(salt)
        return try PBKDF2SHA512(password: password.utf8.map({ Int8(bitPattern: $0) }), salt: [UInt8](saltData), iterations: iterations, keyLength: keyLength)
    }
}

fileprivate extension Digest {
    
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
    var hexString: String {
        bytes.hexString
    }
}

extension Array where Element == UInt8 {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
    
    func toBitArray() -> [String] {
      var toReturn = [String]()
      for num in self {
        toReturn.append(contentsOf: num.mnemonicBits())
      }
      return toReturn
    }
    
}

extension Data {
    
  func toBitArray() -> [String] {
    var toReturn = [String]()
    for num in [UInt8](self) {
      toReturn.append(contentsOf: num.mnemonicBits())
    }
    return toReturn
  }
    
}

fileprivate struct PKCS5 {
    
    enum Error: Swift.Error {
        case invalidInput
    }

    static func PBKDF2SHA512(password: Array<Int8>, salt: Array<UInt8>, iterations: Int = 2_048, keyLength: Int = 64) throws -> Array<UInt8> {
        var bytes = [UInt8](repeating: 0, count: keyLength)

        try bytes.withUnsafeMutableBytes { (outputBytes: UnsafeMutableRawBufferPointer) in
            let status = CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                password,
                password.count,
                salt,
                salt.count,
                CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512),
                UInt32(iterations),
                outputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                keyLength
            )
            guard status == kCCSuccess else {
                throw Error.invalidInput
            }
        }
        return bytes
    }
}

fileprivate enum WordCount: Int {
    
    case twelve = 12
    case fifteen = 15
    case eighteen = 18
    case twentyOne = 21
    case twentFour = 24

    var bitLength: Int {
        self.rawValue / 3 * 32
    }

    var checksumLength: Int {
        self.rawValue / 3
    }
}

fileprivate extension UInt8 {
    
  func mnemonicBits() -> [String] {
    let totalBitsCount = MemoryLayout<UInt8>.size * 8

    var bitsArray = [String](repeating: "0", count: totalBitsCount)

    for j in 0 ..< totalBitsCount {
      let bitVal: UInt8 = 1 << UInt8(totalBitsCount - 1 - j)
      let check = self & bitVal

      if check != 0 {
        bitsArray[j] = "1"
      }
    }
    return bitsArray
  }
    
}

fileprivate extension String {
    
    func mnemonicData() -> Data? {
        guard self.count % 2 == 0 else { return nil }
        let length = self.count
        let dataLength = length / 2
        var dataToReturn = Data(capacity: dataLength)

        var outIndex = 0
        var outChars = ""
        for (_, char) in enumerated() {
            outChars += String(char)
            if outIndex % 2 == 1 {
                guard let i = UInt8(outChars, radix: 16) else { return nil }
                dataToReturn.append(i)
                outChars = ""
            }
            outIndex += 1
        }

        return dataToReturn
    }

    func pad(toSize: Int) -> String {
        guard self.count < toSize else { return self }
        var padded = self
        for _ in 0..<(toSize - self.count) {
            padded = "0" + padded
        }
        return padded
    }

    /// turns an array of "0"s and "1"s into bytes. fails if count is not modulus of 8
    func bitStringToBytes() -> Data? {
        let length = 8
        guard self.count % length == 0 else {
            return nil
        }
        var data = Data(capacity: self.count)

        for i in 0 ..< self.count / length {
            let startIdx = self.index(self.startIndex, offsetBy: i * length)
            let subArray = self[startIdx ..< self.index(startIdx, offsetBy: length)]
            let subString = String(subArray)
            guard let byte = UInt8(subString, radix: 2) else {
                return nil
            }
            data.append(byte)
        }
        return data
    }
    
}
