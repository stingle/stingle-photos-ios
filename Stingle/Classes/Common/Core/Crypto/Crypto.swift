import Foundation
import Sodium
import Clibsodium

public struct Constants {
	
	public static let FileTypeGeneral = 1
	public static let FileTypePhoto = 2
	public static let FileTypeVideo = 3
	public static let FileTypeLen = 1
	public static let FileBeggining:String = "SP"
	public static let KeyFileBeggining:String = "SPK"
	
	public static let CurrentFileVersion:Int = 1
	public static let CurrentHeaderVersion:Int = 1
	public static let CurrentKeyFileVersion:Int = 1
	
	public static let PwdSaltFilename = "pwdSalt"
	public static let SKNONCEFilename = "skNonce"
	public static let PrivateKeyFilename = "private"
	public static let PublicKeyFilename = "public"
	public static let ServerPublicKeyFilename = "server_public"
	
	public static let XCHACHA20POLY1305_IETF_CONTEXT = "__data__"
	public static let MAX_BUFFER_LENGTH = 1024*1024*64
	public static let FileExtension = ".sp"
	public static let FileNameLen = 32

	public static let FileBegginingLen:Int = Constants.FileBeggining.bytes.count
	public static let FileFileVersionLen = 1
	public static let FileChunksizeLen = 4
	public static let FileDataSizeLen = 8
	public static let FileNameSizeLen = 4
	public static let FileVideoDurationlen = 4
	public static let HeaderVersionLen = 1
	public static let FileHeaderSizeLen = 4
	public static let FileFileIdLen = 32
	public static let FileHeaderBeginningLen:Int = Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Constants.FileHeaderSizeLen
	
	public static let KeyFileTypeBundleEncrypted = 0
	public static let KeyFileTypeBundlePlain = 1
	public static let KeyFileTypePublicPlain = 2
	
	public static let KeyFileBegginingLen:Int = Constants.KeyFileBeggining.bytes.count
	public static let KeyFileVerLen = 1
	public static let KeyFileTypeLen = 1
	public static let KeyFileHeaderLen = 0
	public static let KdfDifficultyNormal = 1
	public static let KdfDifficultyHard = 2
	public static let KdfDifficultyUltra = 3
	public static let PWHASH_LEN = 64
}

public class Crypto {
	
	private let bufSize = 1024 * 1024
	private let pivateBufferSize = 256
	private let sodium: Sodium
	private let hexArray:[Character] = [Character]("0123456789ABCDEF")
	
	public init() {
		self.sodium = Sodium()
	}
	
	public func generateMainKeypair(password:String ) throws {
		try self.generateMainKeypair(password:password, privateKey:nil, publicKey:nil)
	}
	
	public func generateMainKeypair(password: String , privateKey: Bytes?, publicKey: Bytes?) throws {
		guard let pwdSalt: Bytes = self.sodium.randomBytes.buf(length: self.sodium.pwHash.SaltBytes) else {
			throw CryptoError.Internal.randomBytesGenerationFailure
		}
		
		_ = try self.savePrivateFile(filename: Constants.PwdSaltFilename, data: pwdSalt)
		
		var newPrivateKey: Bytes?  = nil
		var newPublicKey: Bytes?  = nil
		
		if(privateKey == nil || publicKey == nil) {
			guard let keyPair = sodium.box.keyPair() else {
				throw CryptoError.Internal.keyPairGenerationFailure
			}
			newPrivateKey = privateKey ?? keyPair.secretKey
			newPublicKey = publicKey ?? keyPair.publicKey
		}
		
		let pwdKey = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
		
		guard let pwdEncNonce = self.sodium.randomBytes.buf(length: sodium.secretBox.NonceBytes) else {
			throw CryptoError.Internal.randomBytesGenerationFailure
		}
		_ = try self.savePrivateFile(filename: Constants.SKNONCEFilename, data: pwdEncNonce)
		
		let encryptedPrivateKey = try self.encryptSymmetric(key: pwdKey, nonce: pwdEncNonce, data: newPrivateKey)
		
		_ = try self.savePrivateFile(filename: Constants.PrivateKeyFilename, data: encryptedPrivateKey)
		_ = try self.savePrivateFile(filename: Constants.PublicKeyFilename, data: newPublicKey!)
	}
	
	public func getPrivateKey(password: String) throws  -> Bytes {
		let encKey = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
		let encPrivKey = try self.readPrivateFile(filename: Constants.PrivateKeyFilename)
		let nonce = try self.readPrivateFile(filename: Constants.SKNONCEFilename)
		let privateKey = try self.decryptSymmetric(key:encKey, nonce:nonce, data:encPrivKey)
		return privateKey
	}
	
	public func getPrivateKeyFromExportedKey(password: String, encPrivKey: Bytes) throws -> Bytes {
		let nonce = try self.readPrivateFile(filename: Constants.SKNONCEFilename)
		let decPK = try self.decryptSymmetric(key: self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyHard), nonce: nonce, data: encPrivKey)
		return try self.encryptSymmetric(key: self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal), nonce: nonce, data: decPK)
	}
	
	public func getKeyFromPassword(password: String, difficulty: Int) throws -> Bytes {
		let salt = try self.readPrivateFile(filename: Constants.PwdSaltFilename)
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
		
	public func getPasswordHashForStorage(password: String) throws -> [String: String]? {
		guard let salt = self.getRandomBytes(lenght: sodium.pwHash.SaltBytes) else {
			return nil
		}
		let hash =  try self.getPasswordHashForStorage(password: password, salt: salt)
		guard let saltHex = sodium.utils.bin2hex(salt) else {
			return nil
		}
		return ["hash": hash, "salt": saltHex]
	}
	
	public func getPasswordHashForStorage(password: String, salt: String) throws -> String {
		guard let data = self.sodium.utils.hex2bin(salt) else {
			return ""
		}
		return try self.getPasswordHashForStorage(password: password, salt: data)
	}
	
	private func getPasswordHashForStorage(password: String, salt: Bytes) throws -> String {
		guard let hash = self.sodium.pwHash.hash(outputLength: Constants.PWHASH_LEN, passwd: password.bytes, salt: salt, opsLimit: self.sodium.pwHash.OpsLimitModerate, memLimit: self.sodium.pwHash.MemLimitModerate, alg: .Argon2ID13) else {
			throw CryptoError.Internal.hashGenerationFailure
		}
		guard let hex = self.sodium.utils.bin2hex(hash)?.uppercased() else {
			throw CryptoError.Internal.hashGenerationFailure
		}
		return hex
	}
	
	public func importKeyBundle(keys: Bytes, password: String) throws {
		var offset:Int = 0
		let fileBegginingStr:String = String(bytes: Bytes(keys[offset..<(offset + Constants.KeyFileBegginingLen)]), encoding: String.Encoding.utf8) ?? ""
		if fileBegginingStr != Constants.KeyFileBeggining {
			throw CryptoError.Bundle.incorrectKeyFileBeginning
		}
		offset += Constants.KeyFileBegginingLen
		let keyFileVersion = keys[offset]
		if keyFileVersion > Constants.CurrentKeyFileVersion {
			throw CryptoError.Bundle.incorrectKeyFileVersion
		}
		offset += 1
		
		let keyFileType = keys[offset]
		if keyFileType != Constants.KeyFileTypeBundleEncrypted && keyFileType != Constants.KeyFileTypeBundlePlain && keyFileType != Constants.KeyFileTypePublicPlain {
			throw CryptoError.Bundle.incorrectKeyFileType
		}
		offset += 1
		
		let publicKey = keys[offset..<(offset + self.sodium.box.PublicKeyBytes)]
		offset += self.sodium.box.PublicKeyBytes
		if keyFileType == Constants.KeyFileTypeBundleEncrypted {
			let encryptedPrivateKey = keys[offset..<(offset + sodium.box.SecretKeyBytes + sodium.secretBox.MacBytes)]
			offset += self.sodium.box.SecretKeyBytes + self.sodium.secretBox.MacBytes
			
			let pwdSalt = keys[offset..<(offset + self.sodium.pwHash.SaltBytes)]
			offset += self.sodium.pwHash.SaltBytes
			
			let skNonce = keys[offset..<(offset + self.sodium.secretBox.NonceBytes)]
			offset += self.sodium.secretBox.NonceBytes
			
			try self.savePrivateFile(filename: Constants.PublicKeyFilename, data: Bytes(publicKey))
			try self.savePrivateFile(filename: Constants.PwdSaltFilename, data: Bytes(pwdSalt))
			try self.savePrivateFile(filename: Constants.SKNONCEFilename, data: Bytes(skNonce))
			let pK = try self.getPrivateKeyFromExportedKey(password: password, encPrivKey: Bytes(encryptedPrivateKey))
			try self.savePrivateFile(filename: Constants.PrivateKeyFilename, data: pK)
			
		} else if keyFileType == Constants.KeyFileTypePublicPlain {
			_ = try self.savePrivateFile(filename: Constants.PublicKeyFilename, data: Bytes(publicKey))
		}
	}
	
	func importServerPublicKey(pbk:Bytes) throws {
		_ = try self.savePrivateFile(filename: Constants.ServerPublicKeyFilename, data: pbk)
	}
		
    func getServerPublicKey() throws -> Bytes {
		return try self.readPrivateFile(filename: Constants.ServerPublicKeyFilename)
    }
	
	public func getPrivateKeyForExport(password: String) throws -> Bytes {
		let encPK = try self.readPrivateFile(filename: Constants.PrivateKeyFilename)
		let nonce = try self.readPrivateFile(filename: Constants.SKNONCEFilename)
		let key = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
		
		let decPK = try self.decryptSymmetric(key: key, nonce: nonce, data: encPK)
		let encryptKey = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyHard)
		let encrypt = try self.encryptSymmetric(key: encryptKey, nonce: nonce, data: decPK)
		return encrypt
	}
	
	public func exportPublicKey() throws -> Bytes {
		var pbk = [UInt8]()
		pbk += Constants.KeyFileBeggining.bytes
		pbk += Crypto.toBytes(value: Constants.CurrentKeyFileVersion)
		pbk += Crypto.toBytes(value: Constants.KeyFileTypePublicPlain)
		do {
			let pbkBytes = try self.readPrivateFile(filename: Constants.PublicKeyFilename)
			pbk += pbkBytes
		} catch {
			throw error
		}
		return pbk
	}
	
	public func exportKeyBundle(password: String) throws -> Bytes {
		var result = [UInt8]()
		result.append(contentsOf: Constants.KeyFileBeggining.bytes)
		result.append(UInt8(Constants.CurrentKeyFileVersion))
		result.append(UInt8(Constants.KeyFileTypeBundleEncrypted))

		let publicKeyFile = try self.readPrivateFile(filename: Constants.PublicKeyFilename)
		result.append(contentsOf: publicKeyFile)

		let privateKeyForExport = try self.getPrivateKeyForExport(password: password)
		result.append(contentsOf: privateKeyForExport)

		let pwdSalt = try self.readPrivateFile(filename: Constants.PwdSaltFilename)
		result.append(contentsOf: pwdSalt)

		let nonce = try self.readPrivateFile(filename: Constants.SKNONCEFilename)
		result.append(contentsOf: nonce)
		
		return result
	}
	
	private func encryptSymmetric(key: Bytes?, nonce: Bytes?, data: Bytes?) throws -> Bytes {
		
		guard let key = key, key.count ==  self.sodium.secretBox.KeyBytes else {
			throw CryptoError.General.incorrectKeySize
		}
		
		guard let nonce = nonce, nonce.count == self.sodium.secretBox.NonceBytes else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		guard let data = data, data.count > 0 else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		guard let cypherText = self.sodium.secretBox.seal(message: data, secretKey: key, nonce: nonce) else {
			throw CryptoError.Internal.sealFailure
		}
		
		return cypherText
	}
	
	private func decryptSymmetric(key: Bytes?, nonce: Bytes?, data: Bytes?) throws -> Bytes {
		
		guard let key = key, key.count == self.sodium.secretBox.KeyBytes else {
			throw CryptoError.General.incorrectKeySize
		}
		
		guard let nonce = nonce, nonce.count == self.sodium.secretBox.NonceBytes else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		guard let data = data, data.count > 0 else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		guard let plainText = sodium.secretBox.open(authenticatedCipherText: data, secretKey: key, nonce: nonce) else {
			throw CryptoError.Internal.openFailure
		}
		
		return plainText
	}
	
	private func getNewHeader(symmetricKey: Bytes?, dataSize: UInt, filename: String, fileType: Int, fileId: Bytes?, videoDuration: UInt32) throws  -> Header {
		guard  let symmetricKey = symmetricKey, symmetricKey.count == self.sodium.keyDerivation.KeyBytes else {
			throw CryptoError.General.incorrectKeySize
		}
		
		guard let fileId = fileId, fileId.count > 0 else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		let header = Header(fileVersion: UInt8(Constants.CurrentFileVersion), fileId: fileId, headerVersion: UInt8(Constants.CurrentHeaderVersion), chunkSize: UInt32(bufSize), dataSize: UInt64(dataSize), symmetricKey:symmetricKey, fileType: UInt8(fileType), fileName: filename, videoDuration: UInt32(videoDuration))
		return header
	}
	
	private func writeHeader(output: OutputStream, header: Header, publicKey: Bytes?) throws  {
		// File beggining - 2 bytes
		var numWritten = output.write(Constants.FileBeggining.bytes, maxLength: Constants.FileBegginingLen)
		
		// File version number - 1 byte
		numWritten += output.write([UInt8(Constants.CurrentFileVersion)], maxLength: Constants.FileFileVersionLen)
		
		// File ID - 32 bytes
		numWritten += output.write(header.fileId, maxLength: Constants.FileFileIdLen)
		
		guard let publicKey = publicKey else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		let headerBytes = self.toBytes(header:header)
		
		guard let encHeader = self.sodium.box.seal(message: headerBytes, recipientPublicKey: publicKey) else {
			throw CryptoError.Internal.sealFailure
		}
		
		// Write header size - 4 bytes
		numWritten += output.write(Crypto.toBytes(value: Int32(encHeader.count)), maxLength: Constants.FileHeaderSizeLen)
		
		// Write header3
		numWritten += output.write(encHeader, maxLength: encHeader.count)
		guard numWritten ==  (Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Constants.FileHeaderSizeLen + encHeader.count) else {
			throw CryptoError.IO.writeFailure
		}
	}
		
	func getFileHeader(input: InputStream) throws -> Header {
		var buf:Bytes = Bytes(repeating: 0, count: Constants.FileHeaderBeginningLen)
		guard Constants.FileHeaderBeginningLen == input.read(&buf, maxLength: Constants.FileHeaderBeginningLen) else {
			throw CryptoError.IO.readFailure
		}
		var offset:Int = 0
		let fileBegginingStr: String = String(bytes: Bytes(buf[offset..<(offset + Constants.FileBegginingLen)]), encoding: String.Encoding.utf8) ?? ""
		if fileBegginingStr != Constants.FileBeggining {
			throw CryptoError.Header.incorrectFileBeggining
		}
		offset += Constants.FileBegginingLen
		
		let fileVersion:UInt8 = buf[offset]
		if fileVersion != Constants.CurrentFileVersion {
			throw CryptoError.Header.incorrectFileVersion
		}
		offset += Constants.FileFileVersionLen
		
		let fileId:Bytes = Bytes(buf[offset..<offset + Constants.FileFileIdLen])
		offset += Constants.FileFileIdLen
		
		let headerSize:UInt32 = Crypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
		offset += Constants.FileHeaderSizeLen
		guard headerSize > 0 else {
			throw CryptoError.Header.incorrectHeaderSize
		}
		
		var header:Header = Header()
		
		header.fileId = fileId
		header.fileVersion = fileVersion
		header.headerSize = headerSize
		header.overallHeaderSize = UInt32(Constants.FileHeaderBeginningLen) + headerSize
		
		var encHeaderBytes = Bytes(repeating: 0, count: Int(headerSize))
		let numRead = input.read(&encHeaderBytes, maxLength: Int(headerSize))
		guard numRead > 0  else {
			throw CryptoError.IO.readFailure
		}
		encHeaderBytes = encHeaderBytes.dropLast(Int(headerSize) - numRead)
		let publicKey = try readPrivateFile(filename: Constants.PublicKeyFilename)
		
		guard let privateKey:Bytes = KeyManagement.key else {
			throw CryptoError.Bundle.pivateKeyIsEmpty
		}
		guard let headerBytes = sodium.box.open(anonymousCipherText: encHeaderBytes, recipientPublicKey: publicKey, recipientSecretKey: privateKey) else {
			throw CryptoError.Internal.openFailure
		}
		
		offset = 0
		header.headerVersion = headerBytes[offset]
		offset += Constants.HeaderVersionLen
		
		header.chunkSize = Crypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileChunksizeLen]))
		offset += Constants.FileChunksizeLen
		
		header.dataSize = Crypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileDataSizeLen]))
		offset += Constants.FileDataSizeLen
		
		header.symmetricKey = Bytes(headerBytes[offset..<offset + sodium.keyDerivation.KeyBytes])
		offset += sodium.keyDerivation.KeyBytes
		
		header.fileType = headerBytes[offset]
		offset += Constants.FileTypeLen
		
		let fileNameSize:Int = Crypto.fromBytes(b:Bytes(headerBytes[offset..<offset + Constants.FileNameSizeLen]))
		offset += Constants.FileNameSizeLen
		header.fileName = String(bytes: Bytes(headerBytes[offset..<offset + fileNameSize]), encoding: String.Encoding.utf8) ?? ""
		
		offset += fileNameSize
		header.videoDuration = Crypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileVideoDurationlen]))
		return header
	}
	
	public func encryptFile(input: InputStream, output: OutputStream, filename: String, fileType: Int, dataLength: UInt, fileId: Bytes, videoDuration:UInt32) throws {
		let publicKey = try self.readPrivateFile(filename: Constants.PublicKeyFilename)
		let symmetricKey = self.sodium.keyDerivation.key()
		let header = try getNewHeader(symmetricKey: symmetricKey, dataSize: dataLength, filename: filename, fileType: fileType, fileId: fileId, videoDuration: videoDuration)
		try self.writeHeader(output: output, header: header, publicKey: publicKey)
		try self.encryptData(input: input, output: output, header: header)
	}
	
	@discardableResult
	private func encryptData(input: InputStream, output: OutputStream, header: Header?) throws -> Bool {
		guard let header = header, (1...self.bufSize).contains(Int(header.chunkSize)) else {
			throw CryptoError.Header.incorrectChunkSize
		}
		
		var chunkNumber:UInt64 = 1
		
		var buf:Bytes = []
		var numRead = 0
		var diff: Int = 0
		
		var numWrite: Int = 0
		repeat {
			buf = Bytes(repeating: 0, count: Int(header.chunkSize))
			numRead = input.read(&buf, maxLength: buf.count)
			assert(numRead >= 0)
			diff = Int(header.chunkSize) - numRead
			assert(diff >= 0)
			if diff > 0 {
				buf = Bytes(buf[..<numRead])
			}
			let keyBytesLength = self.sodium.aead.xchacha20poly1305ietf.KeyBytes
			guard let chunkKey = self.sodium.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: keyBytesLength, context: Constants.XCHACHA20POLY1305_IETF_CONTEXT) else {
				throw CryptoError.Internal.keyDerivationFailure
			}
			guard chunkKey.count == self.sodium.aead.xchacha20poly1305ietf.KeyBytes else {
				throw CryptoError.General.incorrectKeySize
			}
			guard let (authenticatedCipherText, chunkNonce) : (Bytes, Bytes)  = sodium.aead.xchacha20poly1305ietf.encrypt(message: buf, secretKey: chunkKey) else {
				throw CryptoError.General.incorrectKeySize
			}
			numWrite = output.write(chunkNonce, maxLength: chunkNonce.count)
			assert(numWrite == chunkNonce.count)
			numWrite = output.write(authenticatedCipherText, maxLength:authenticatedCipherText.count)
			assert(numWrite == authenticatedCipherText.count)
			chunkNumber += UInt64(1)
		} while (diff == 0)
		
		output.close();
		return true;
	}
	
	public func decryptFileAsync(input: InputStream, output: OutputStream, completion: ((Bool, Error?) -> Void)? = nil) {
	let body = {() -> Void in
		var result = false
		var decError:Error? = nil
		do {
			result = try self.decryptFile(input: input, output: output)
		} catch {
			decError = error
			result = false
		}
		guard let completion = completion else {
			return
		}
		completion(result, decError)
		}
		DispatchQueue.global(qos: .background).async {
			body()
		}
	}
	
	public func decryptFile(input: InputStream, output: OutputStream, completionHandler:  ((Bytes?) -> Swift.Void)? = nil) throws -> Bool {
		let header = try getFileHeader(input:input)
		try self.decryptData(input: input, header: header) { chunk in
			guard let chunk = chunk else {
				return
			}
			if let completion = completionHandler {
				completion(chunk)
			} else {
				let numWrite = output.write(chunk, maxLength: chunk.count)
				assert(numWrite == chunk.count)
			}
		}
		output.close();
		return true
	}
	
	public func decryptData(data: Bytes, header: Header?, chunkNumber: UInt64, completionHandler:  @escaping (Bytes?) -> Swift.Void) throws -> Bool {
		guard let header = header, (1...self.bufSize).contains(Int(header.chunkSize)) else {
			throw CryptoError.Header.incorrectChunkSize
		}
		let dataReadSize:Int = Int(header.chunkSize) + self.sodium.aead.xchacha20poly1305ietf.ABytes + sodium.aead.xchacha20poly1305ietf.NonceBytes
		var offset = 0
		var index:UInt64 = 0
		repeat {
			let size = min(dataReadSize, data.count - offset)
			let buf:Bytes = Bytes(data[offset..<size])
			offset += size
			let  decryptedData = try self.decryptChunk(chunkData: buf, chunkNumber: chunkNumber + index, header: header)
			assert(header.chunkSize == decryptedData.count || (size < dataReadSize))
			completionHandler(decryptedData)
			index += UInt64(1)
		} while (offset < data.count)
		return true
	}
	
	@discardableResult
	public func decryptData(input:InputStream, header:Header?, completionHandler:  @escaping (Bytes?) -> Swift.Void) throws -> Bool {
		guard let header = header, (1...self.bufSize).contains(Int(header.chunkSize)) else {
			throw CryptoError.Header.incorrectChunkSize
		}
		var chunkNumber:UInt64 = 1
		let dataReadSize:Int = Int(header.chunkSize) + self.sodium.aead.xchacha20poly1305ietf.ABytes + self.sodium.aead.xchacha20poly1305ietf.NonceBytes
		var buf:Bytes = Bytes(repeating: 0, count: dataReadSize)
		var numRead = 0
		var diff:Int = 0
		repeat {
			numRead = input.read(&buf, maxLength: buf.count)
			diff = dataReadSize - numRead
			if diff > 0 {
				buf = buf.dropLast(diff)
			}
			let  decryptedData = try self.decryptChunk(chunkData: buf, chunkNumber: chunkNumber, header: header)
			assert(header.chunkSize == decryptedData.count || (diff != 0))
			completionHandler(decryptedData)
			chunkNumber += UInt64(1)
		} while (diff == 0)
		return true
	}
	
	private func decryptChunk(chunkData: Bytes, chunkNumber: UInt64, header: Header) throws -> Bytes {
		let keyBytesLength = self.sodium.aead.xchacha20poly1305ietf.KeyBytes
		guard let chunkKey = self.sodium.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: keyBytesLength, context: Constants.XCHACHA20POLY1305_IETF_CONTEXT) else {
			throw CryptoError.Internal.keyDerivationFailure
		}
		assert(keyBytesLength == chunkKey.count)
		guard let  decryptedData = self.sodium.aead.xchacha20poly1305ietf.decrypt(nonceAndAuthenticatedCipherText: chunkData, secretKey: chunkKey) else {
			throw CryptoError.Internal.decryptFailure
		}
		return decryptedData
	}
	
	@discardableResult
	private func savePrivateFile(filename: String, data: Bytes?) throws -> Bool {
		
		guard let fullPath = SPFileManager.folder(for: .Private)?.appendingPathComponent(filename) else {
			throw CryptoError.PrivateFile.invalidPath
		}
		
		guard let out = OutputStream(url: fullPath, append: false) else {
			throw CryptoError.IO.writeFailure
		}
		out.open()
		
		guard let data = data else {
			throw CryptoError.PrivateFile.invalidData
		}
		
		guard data.count == out.write(data, maxLength: data.count) else {
			throw CryptoError.IO.writeFailure
		}
		out.close()
		return true
	}
	
	private func readPrivateFile(filename: String) throws -> Bytes {
		
		guard let fullPath = SPFileManager.folder(for: .Private)?.appendingPathComponent(filename) else {
			throw CryptoError.PrivateFile.invalidPath
		}
		guard let input:InputStream = InputStream(url: fullPath) else {
			throw CryptoError.IO.readFailure
		}
		input.open()
		
		var buffer = Bytes(repeating: 0, count: self.pivateBufferSize)
		var numRead:Int = 0
		var outBuff = Bytes(repeating: 0, count: 0)
		
		repeat {
			numRead = input.read(&buffer, maxLength: self.pivateBufferSize)
			if numRead < 0 {
				throw CryptoError.IO.readFailure
			}
			outBuff += buffer[0..<numRead]
		} while (numRead > 0)
		
		
		if outBuff.count <= 0 {
			throw CryptoError.IO.readFailure
		}
		input.close()
		return outBuff
	}
}

public struct Header {
	
	public var fileVersion:UInt8 = 0
	public var fileId:Bytes = []
	public var headerSize:UInt32?
	public var headerVersion:UInt8 = 0
	public var chunkSize:UInt32 = 0
	public var dataSize:UInt64 = 0
	public var symmetricKey:Bytes = []
	public var fileType:UInt8 = 0
	public var fileName:String?
	public var videoDuration:UInt32 = 0
	public var overallHeaderSize:UInt32?
	
	func desc() {
		print("fileVersion : \(fileVersion)")
		print("fileId : \(fileId)")
		print("headerSize : \(headerSize ?? 0)")
		print("headerVersion : \(headerVersion)")
		print("chunkSize : \(chunkSize)")
		print("dataSize : \(dataSize)")
		print("symmetricKey : \(symmetricKey)")
		print("fileType : \(fileType)")
		print("fileName : \(fileName ?? "noname")")
		print("videoDuration : \(videoDuration)")
		print("overallHeaderSize : \(overallHeaderSize ?? 0)")
	}
}

extension Crypto {
	
	public func chunkAdditionalSize  () -> Int {
		return sodium.aead.xchacha20poly1305ietf.ABytes + sodium.aead.xchacha20poly1305ietf.NonceBytes
	}
	
	public func getRandomBytes(lenght:Int) -> Bytes? {
		return sodium.randomBytes.buf(length: lenght)
	}
	
	public func newFileId() -> Bytes? {
		return getRandomBytes(lenght: Constants.FileFileIdLen)
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
	
	public func toBytes(header: Header) -> Bytes {
		
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
	
	public func fromBytes(data:Bytes) -> Header {
		var header = Header()
		var offset:Int = 0
		header.headerVersion = data[0]
		offset += Constants.HeaderVersionLen
		header.chunkSize = Crypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileChunksizeLen]))
		offset += Constants.FileChunksizeLen
		header.dataSize = Crypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileDataSizeLen]))
		offset += Constants.FileDataSizeLen
		header.symmetricKey = Bytes(data[offset..<sodium.keyDerivation.KeyBytes])
		offset += sodium.keyDerivation.KeyBytes
		header.fileType = data[offset]
		offset += Constants.FileTypeLen
		let fileNameSize:Int = Crypto.fromBytes(b:Bytes(data[offset..<offset + Constants.FileNameSizeLen]))
		offset += Constants.FileNameSizeLen
		header.fileName = String(bytes: Bytes(data[offset..<offset + fileNameSize]), encoding: String.Encoding.utf8) ?? ""
		offset += fileNameSize
		header.videoDuration = Crypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileVideoDurationlen]))
		return header
	}
	
	public func getFileHeaders(originalPath: String, thumbPath: String) throws -> String? {
		guard let originBytes = try getFileHeaderBytes(path: originalPath) else {
			return nil
		}
		guard let thumbBytes = try getFileHeaderBytes(path: thumbPath) else {
			return nil
		}

		return self.bytesToBase64(data: originBytes)! + "*" + self.bytesToBase64(data: thumbBytes)!
    }
	
	public func getFileHeaderBytes(path: String) throws -> Bytes? {
		guard let input = InputStream(fileAtPath: path) else {
			return nil
		}
		input.open()
        let overallHeaderSize = try getOverallHeaderSize(input: input)
		input.close()

		guard let newInput = InputStream(fileAtPath: path) else {
			return nil
		}
		newInput.open()
		var header = Bytes(repeating: 0, count: overallHeaderSize)
		guard overallHeaderSize == newInput.read(&header, maxLength: overallHeaderSize) else {
			return nil
		}
		newInput.close()
        return header
    }

	public func getOverallHeaderSize(input: InputStream) throws -> Int  {
        // Read and validate file beginning
		var buf:Bytes = Bytes(repeating: 0, count: Constants.FileHeaderBeginningLen)
		guard Constants.FileHeaderBeginningLen == input.read(&buf, maxLength: Constants.FileHeaderBeginningLen) else {
			throw CryptoError.IO.readFailure
		}
		var offset:Int = 0
		let fileBegginingStr: String = String(bytes: Bytes(buf[offset..<(offset + Constants.FileBegginingLen)]), encoding: String.Encoding.utf8) ?? ""
		if fileBegginingStr != Constants.FileBeggining {
			throw CryptoError.Header.incorrectFileBeggining
		}
		offset += Constants.FileBegginingLen
		
		let fileVersion:UInt8 = buf[offset]
		if fileVersion != Constants.CurrentFileVersion {
			throw CryptoError.Header.incorrectFileVersion
		}
		offset += Constants.FileFileVersionLen
		
		offset += Constants.FileFileIdLen
		
		let headerSize:UInt32 = Crypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
		offset += Constants.FileHeaderSizeLen
		guard headerSize > 0 else {
			throw CryptoError.Header.incorrectHeaderSize
		}
		offset += Int(headerSize)
        return offset
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
