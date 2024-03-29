import Foundation
import Sodium
import Clibsodium

public extension STCrypto {
    
    struct Constants {
        
        static public let FileTypeGeneral = 1
        static public let FileTypePhoto = 2
        static public let FileTypeVideo = 3
        static public let FileTypeLen = 1
        static public let FileBeggining:String = "SP"
        static public let KeyFileBeggining:String = "SPK"
        
        static public let CurrentFileVersion:Int = 1
        static public let CurrentHeaderVersion:Int = 1
        static public let CurrentKeyFileVersion:Int = 1
        
        static public let PwdSaltFilename = "pwdSalt"
        static public let SKNONCEFilename = "skNonce"
        static public let PrivateKeyFilename = "private"
        static public let PublicKeyFilename = "public"
        static public let ServerPublicKeyFilename = "server_public"
        
        static public let XCHACHA20POLY1305_IETF_CONTEXT = "__data__"
        static public let MAX_BUFFER_LENGTH = 1024*1024*64
        static public let FileExtension = ".sp"
        static public let FileNameLen = 32
        
        static public let FileBegginingLen:Int = Constants.FileBeggining.bytes.count
        static public let FileFileVersionLen = 1
        static public let FileChunksizeLen = 4
        static public let FileDataSizeLen = 8
        static public let FileNameSizeLen = 4
        static public let FileVideoDurationlen = 4
        static public let HeaderVersionLen = 1
        static public let FileHeaderSizeLen = 4
        static public let FileFileIdLen = 32
        static public let FileHeaderBeginningLen:Int = Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Constants.FileHeaderSizeLen
        
        static public let KeyFileTypeBundleEncrypted = 0
        static public let KeyFileTypeBundlePlain = 1
        static public let KeyFileTypePublicPlain = 2
        
        static public let KeyFileBegginingLen:Int = Constants.KeyFileBeggining.bytes.count
        static public let KeyFileVerLen = 1
        static public let KeyFileTypeLen = 1
        static public let KeyFileHeaderLen = 0
        static public let KdfDifficultyNormal = 1
        static public let KdfDifficultyHard = 2
        static public let KdfDifficultyUltra = 3
        static public let PWHASH_LEN = 64
        
        static public let CurrentAlbumMedadataVersionLen = 1
        static public let CurrentAlbumMedadataVersion = 1
        static public let AlbumIDLen = 32
    }
    
    typealias ProgressHandler = ((_ progress: Progress, _ stop: inout Bool) -> Void)
    
}

public class STCrypto {
    
    private let pivateBufferSize = 256
	private let hexArray:[Character] = [Character]("0123456789ABCDEF")
    
    let bufSize = 1024 * 1024
    let sodium: Sodium
	
	public init() {
		self.sodium = Sodium()
	}
    
    func getPublicKeyFromPrivateKey(byte: Bytes) throws -> Bytes {
        guard let publicKey = self.sodium.secretBox.exportPublicKey(secretKey: byte) else {
            throw CryptoError.Internal.sealFailure
        }
        return publicKey
    }
    
    func decryptSeal(enc: Bytes, publicKey: Bytes, privateKey: Bytes) throws -> Bytes {
        guard let decryptSeal = self.sodium.box.open(anonymousCipherText: enc, recipientPublicKey: publicKey, recipientSecretKey: privateKey) else {
            throw CryptoError.Internal.openFailure
        }
        return decryptSeal
    }
			
	public func getPasswordHashForStorage(password: String) throws -> [String: String] {
		guard let salt = self.getRandomBytes(lenght: sodium.pwHash.SaltBytes) else {
            throw CryptoError.Internal.hashGenerationFailure
		}
		let hash =  try self.getPasswordHashForStorage(password: password, salt: salt)
        guard let saltHex = self.sodium.utils.bin2hex(salt) else {
            throw CryptoError.Internal.hashGenerationFailure
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
		return try self.readPrivateFile(fileName: Constants.ServerPublicKeyFilename)
    }
	
	public func getPrivateKeyForExport(password: String) throws -> Bytes {
		let encPK = try self.readPrivateFile(fileName: Constants.PrivateKeyFilename)
		let nonce = try self.readPrivateFile(fileName: Constants.SKNONCEFilename)
		let key = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
		
		let decPK = try self.decryptSymmetric(key: key, nonce: nonce, data: encPK)
		let encryptKey = try self.getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyHard)
		let encrypt = try self.encryptSymmetric(key: encryptKey, nonce: nonce, data: decPK)
		return encrypt
	}
	
	public func exportPublicKey() throws -> Bytes {
		var pbk = [UInt8]()
        pbk.append(contentsOf: Constants.KeyFileBeggining.bytes)
        pbk.append(UInt8(Constants.CurrentKeyFileVersion))
        pbk.append(UInt8(Constants.KeyFileTypePublicPlain))
		do {
			let pbkBytes = try self.readPrivateFile(fileName: Constants.PublicKeyFilename)
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

		let publicKeyFile = try self.readPrivateFile(fileName: Constants.PublicKeyFilename)
		result.append(contentsOf: publicKeyFile)

		let privateKeyForExport = try self.getPrivateKeyForExport(password: password)
		result.append(contentsOf: privateKeyForExport)

		let pwdSalt = try self.readPrivateFile(fileName: Constants.PwdSaltFilename)
		result.append(contentsOf: pwdSalt)

		let nonce = try self.readPrivateFile(fileName: Constants.SKNONCEFilename)
		result.append(contentsOf: nonce)
		
		return result
	}
	
    func encryptSymmetric(key: Bytes?, nonce: Bytes?, data: Bytes?) throws -> Bytes {
		
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
	
    func decryptSymmetric(key: Bytes?, nonce: Bytes?, data: Bytes?) throws -> Bytes {
		
		guard let key = key, key.count == self.sodium.secretBox.KeyBytes else {
			throw CryptoError.General.incorrectKeySize
		}
		
		guard let nonce = nonce, nonce.count == self.sodium.secretBox.NonceBytes else {
			throw CryptoError.General.incorrectParameterSize
		}
		
		guard let data = data, data.count > 0 else {
			throw CryptoError.General.incorrectParameterSize
		}
		
        guard let plainText = self.sodium.secretBox.open(authenticatedCipherText: data, secretKey: key, nonce: nonce) else {
			throw CryptoError.Internal.openFailure
		}
		
		return plainText
	}
    
    @discardableResult
    public func encryptFile(inputData: Data, outputUrl: URL, fileName: String, originalFileName: String, fileType: Int, fileId: Bytes, videoDuration: UInt32, publicKey: Bytes? = nil, progressHandler: ProgressHandler? = nil) throws -> (header: STHeader, encriptedHeader: Bytes) {
        
        let inputStream = InputStream(data: inputData)
        let dataLength: UInt = UInt(inputData.count)

        let outputUrl = outputUrl.appendingPathComponent(fileName)

        guard let outputStream = OutputStream(toFileAtPath: outputUrl.path, append: false) else {
            throw CryptoError.General.creationFailure
        }
        
        inputStream.open()
        outputStream.open()
        
        defer {
            inputStream.close()
            outputStream.close()
        }
        let result = try self.encryptFile(input: inputStream, output: outputStream, filename: originalFileName, fileType: fileType, dataLength: dataLength, fileId: fileId, videoDuration: videoDuration, publicKey: publicKey, progressHandler: progressHandler)
        return result
    }
    
    @discardableResult
    public func encryptFile(inputUrl: URL, outputUrl: URL, fileName: String, originalFileName: String, fileType: Int, dataLength: UInt, fileId: Bytes, videoDuration: UInt32, publicKey: Bytes? = nil, progressHandler: ProgressHandler? = nil) throws -> (header: STHeader, encriptedHeader: Bytes) {
        
        guard let inputStream = InputStream(fileAtPath: inputUrl.path) else {
            throw CryptoError.General.creationFailure
        }

        let outputUrl = outputUrl.appendingPathComponent(fileName)

        guard let outputStream = OutputStream(toFileAtPath: outputUrl.path, append: false) else {
            throw CryptoError.General.creationFailure
        }
        
        inputStream.open()
        outputStream.open()
        
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        let result = try self.encryptFile(input: inputStream, output: outputStream, filename: originalFileName, fileType: fileType, dataLength: dataLength, fileId: fileId, videoDuration: videoDuration, publicKey: publicKey, progressHandler: progressHandler)
        return result
    }
	
    @discardableResult
    public func encryptFile(input: InputStream, output: OutputStream, filename: String, fileType: Int, dataLength: UInt, fileId: Bytes, videoDuration: UInt32, publicKey: Bytes? = nil, progressHandler: ProgressHandler? = nil) throws -> (header: STHeader, encriptedHeader: Bytes) {
        
		let publicKey = try (publicKey ?? self.readPrivateFile(fileName: Constants.PublicKeyFilename))
		let symmetricKey = self.sodium.keyDerivation.key()
		let header = try getNewHeader(symmetricKey: symmetricKey, dataSize: dataLength, filename: filename, fileType: fileType, fileId: fileId, videoDuration: videoDuration)
        let encriptedHeader = try self.writeHeader(output: output, header: header, publicKey: publicKey)
        try self.encryptData(input: input, output: output, header: header, progressHandler: progressHandler)
    
        return (header, encriptedHeader)
	}
    
    public func generateEncriptedHeader(header: STHeader, publicKey: Bytes? = nil) throws -> String {
        
        let publicKey = try (publicKey ?? self.readPrivateFile(fileName: Constants.PublicKeyFilename))
        
        let outputStream = OutputStream(toMemory: ())
        outputStream.open()
        defer {
            outputStream.close()
        }
        let encriptedHeaderBytes = try self.writeHeader(output: outputStream, header: header, publicKey: publicKey)
        guard let base64Original = self.bytesToBase64Url(data: encriptedHeaderBytes) else {
            throw CryptoError.Header.incorrectHeader
        }
        return base64Original
    }
    
    public func generateEncriptedHeaders(oreginalHeader: STHeader, thumbHeader: STHeader, publicKey: Bytes? = nil) throws -> String {
        let original = try self.generateEncriptedHeader(header: oreginalHeader, publicKey: publicKey)
        let thumb = try self.generateEncriptedHeader(header: thumbHeader, publicKey: publicKey)
        let headers = original + "*" + thumb
        return headers
    }
	
    func encryptData(input: InputStream, output: OutputStream, header: STHeader, progressHandler: ProgressHandler? = nil) throws {
		guard (1...self.bufSize).contains(Int(header.chunkSize)) else {
			throw CryptoError.Header.incorrectChunkSize
		}
		
		var chunkNumber:UInt64 = 1
		
		
		var numRead = 0
		var diff: Int = 0
        
        let progress = Progress()
        
        progress.totalUnitCount = Int64(header.dataSize)
        
        let context = Constants.XCHACHA20POLY1305_IETF_CONTEXT
		var numWrite: Int = 0
        var buf:Bytes = Bytes(repeating: 0, count: Int(header.chunkSize))
		repeat {
            
            if buf.count != Int(header.chunkSize) {
                buf = Bytes(repeating: 0, count: Int(header.chunkSize))
            }
			
			numRead = input.read(&buf, maxLength: buf.count)
			assert(numRead >= 0)
			diff = Int(header.chunkSize) - numRead
			assert(diff >= 0)
			if diff > 0 {
				buf = Bytes(buf[..<numRead])
			}
			let keyBytesLength = self.sodium.aead.xchacha20poly1305ietf.KeyBytes
			guard let chunkKey = self.sodium.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: keyBytesLength, context: context) else {
				throw CryptoError.Internal.keyDerivationFailure
			}
			guard chunkKey.count == self.sodium.aead.xchacha20poly1305ietf.KeyBytes else {
				throw CryptoError.General.incorrectKeySize
			}
            guard let (authenticatedCipherText, chunkNonce) : (Bytes, Bytes)  = self.sodium.aead.xchacha20poly1305ietf.encrypt(message: buf, secretKey: chunkKey) else {
				throw CryptoError.General.incorrectKeySize
			}
			numWrite = output.write(chunkNonce, maxLength: chunkNonce.count)
			assert(numWrite == chunkNonce.count)
			numWrite = output.write(authenticatedCipherText, maxLength: authenticatedCipherText.count)
			
            if numWrite != authenticatedCipherText.count {
                throw CryptoError.General.incorrectKeySize
            }
			chunkNumber += UInt64(1)
            
            progress.completedUnitCount = progress.completedUnitCount + Int64(numRead)
            var stop = false
            progressHandler?(progress, &stop)
            if stop {
                throw CryptoError.General.canceled
            }
            
		} while (diff == 0)
		
		output.close()
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
    
    func validateHeaderData(input: InputStream) throws {
       
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
        
        let headerSize: UInt32 = STCrypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
        offset += Constants.FileHeaderSizeLen
        guard headerSize > 0 else {
            throw CryptoError.Header.incorrectHeaderSize
        }
        
        var encHeaderBytes = Bytes(repeating: 0, count: Int(headerSize))
        let numRead = input.read(&encHeaderBytes, maxLength: Int(headerSize))
                
        guard numRead > 0  else {
            throw CryptoError.IO.readFailure
        }
    }
	
    @discardableResult
    public func decryptFile(input: InputStream, output: OutputStream, header: STHeader? = nil, validateHeader: Bool = true, completionHandler:  ((Bytes?) -> Swift.Void)? = nil) throws -> Bool {
                
        var header = header
        if header == nil {
            header = try getFileHeader(input: input)
        } else if validateHeader {
            try self.validateHeaderData(input: input)
        }

		try self.decryptData(input: input, header: header!) { chunk in
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
			
	@discardableResult
    func savePrivateFile(filename: String, data: Bytes?) throws -> Bool {
        let path = STFileSystem.privateKeyUrl()
		guard let fullPath = path?.appendingPathComponent(filename) else {
			throw CryptoError.PrivateFile.invalidPath
		}
        try? FileManager.default.removeItem(at: fullPath)
		guard let out = OutputStream(url: fullPath, append: false) else {
			throw CryptoError.IO.writeFailure
		}
		out.open()
        defer {
            out.close()
        }
		guard let data = data else {
			throw CryptoError.PrivateFile.invalidData
		}
		
		guard data.count == out.write(data, maxLength: data.count) else {
			throw CryptoError.IO.writeFailure
		}
		
		return true
	}
    
    func readPublicKey() throws -> Bytes {
        return try self.readPrivateFile(fileName: Constants.PublicKeyFilename)
    }
	
    func readPrivateFile(fileName: String) throws -> Bytes {
        let path = STFileSystem.privateKeyUrl(filePath: fileName)
        guard let fullPath = path else {
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
        
        defer {
            input.close()
        }
		
		return outBuff
	}
}
