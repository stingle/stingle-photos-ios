//
//  Crypto.swift
//  Stingle
//
//  Created by Davit Grigoryan on 20.02.2020.
//  Copyright © 2020 Davit Grigoryan. All rights reserved.
//

import Foundation
import Sodium

fileprivate struct Constants {
    public static let FileTypeGeneral = 1
    public static let FileTypePhoto = 2
    public static let FileTypeVideo = 3
    public static let FileTypeLen = 1
    public static let FileBeggining:String = "SP"
    public static let KeyFileBeggining:String = "SPK"
    
    public static let CurrentFileVersion:Int = 1
    public static let CurrentHeaderVersion:Int = 1
    public static let CurrentKeyFileVersion:Int = 1;
    
    public static let PwdSaltFilename = "pwdSalt"
    public static let SKNONCEFilename = "skNonce"
    public static let PrivateKeyFilename = "private"
    public static let PublicKeyFilename = "public"
    public static let ServerPublicKeyFilename = "server_public"

    public static let XCHACHA20POLY1305_IETF_CONTEXT = "__data__"
    public static let MAX_BUFFER_LENGTH = 1024*1024*64;
    
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
    
    private let so:Sodium

    private let hexArray:[Character] = [Character]("0123456789ABCDEF")

    public init() {
        so = Sodium()
    }
    
    public func generateMainKeypair(password:String ) throws {
        try generateMainKeypair(password:password, privateKey:nil, publicKey:nil)
    }
    
    public func generateMainKeypair(password:String , privateKey:Bytes?, publicKey:Bytes?) throws {
        
        guard let pwdSalt:Bytes = so.randomBytes.buf(length: so.pwHash.SaltBytes) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        
        _ = try savePrivateFile(filename: Constants.PwdSaltFilename, data: pwdSalt)
        
        var newPrivateKey:Bytes?  = nil
        var newPublicKey:Bytes?  = nil

        if(privateKey == nil || publicKey == nil) {
            guard let keyPair = so.box.keyPair() else {
                throw CryptoError.Internal.keyPairGenerationFailure
            }
            newPrivateKey = privateKey ?? keyPair.secretKey
            newPublicKey = publicKey ?? keyPair.publicKey
        }
        
        let pwdKey = try getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
        
        guard let pwdEncNonce = so.randomBytes.buf(length: so.secretBox.NonceBytes) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        _ = try savePrivateFile(filename: Constants.SKNONCEFilename, data: pwdEncNonce)
        
        let encryptedPrivateKey = try encryptSymmetric(key: pwdKey, nonce: pwdEncNonce, data: newPrivateKey)
        
        _ = try savePrivateFile(filename: Constants.PrivateKeyFilename, data: encryptedPrivateKey)
        _ = try savePrivateFile(filename: Constants.PublicKeyFilename, data: newPublicKey!)
    }
    
    public func getPrivateKey(password:String) throws  -> Bytes {
        let encKey = try getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal)
        let encPrivKey = try readPrivateFile(filename: Constants.PrivateKeyFilename)
        let nonce = try readPrivateFile(filename: Constants.SKNONCEFilename)
        let privateKey = try decryptSymmetric(key:encKey, nonce:nonce, data:encPrivKey)
        return privateKey
    }

    public func getKeyFromPassword(password:String, difficulty:Int) throws -> Bytes {
        
        let salt = try readPrivateFile(filename: Constants.PwdSaltFilename)
        guard salt.count == so.pwHash.SaltBytes else {
            throw CryptoError.General.incorrectParameterSize
        }

        var opsLimit = so.pwHash.OpsLimitInteractive
        var memlimit = so.pwHash.MemLimitInteractive
        
        switch difficulty {
        case Constants.KdfDifficultyHard:
            opsLimit = so.pwHash.OpsLimitModerate
            memlimit = so.pwHash.MemLimitModerate
            break
        case Constants.KdfDifficultyUltra:
            opsLimit = so.pwHash.OpsLimitSensitive
            memlimit = so.pwHash.MemLimitSensitive
            break
        default:
            break
        }
        
        guard let key = so.pwHash.hash(outputLength: so.secretBox.KeyBytes, passwd: password.bytes, salt: salt, opsLimit: opsLimit, memLimit: memlimit) else {
            throw CryptoError.Internal.hashGenerationFailure
        }
        return key
    }
        
    private func encryptSymmetric(key:Bytes?, nonce:Bytes?, data:Bytes?) throws -> Bytes {

        guard let key = key, key.count ==  so.secretBox.KeyBytes else {
            throw CryptoError.General.incorrectKeySize
        }
        
        guard let nonce = nonce, nonce.count == so.secretBox.NonceBytes else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        guard let data = data, data.count > 0 else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        guard let cypherText = so.secretBox.seal(message: data, secretKey: key, nonce: nonce) else {
            throw CryptoError.Internal.sealFailure
        }
        
        return cypherText
    }
    
    private func decryptSymmetric(key:Bytes?, nonce:Bytes?, data:Bytes?) throws -> Bytes {
        
        guard let key = key, key.count == so.secretBox.KeyBytes else {
            throw CryptoError.General.incorrectKeySize
        }
        
        guard let nonce = nonce, nonce.count == so.secretBox.NonceBytes else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        guard let data = data, data.count > 0 else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        guard let plainText = so.secretBox.open(authenticatedCipherText: data, secretKey: key, nonce: nonce) else {
            throw CryptoError.Internal.openlFailure
        }
        
        return plainText
    }
    
    private func getNewHeader(symmetricKey:Bytes?, dataSize:UInt, filename:String, fileType:Int, fileId:Bytes?, videoDuration:Int) throws  -> Header {
        guard  let symmetricKey = symmetricKey, symmetricKey.count == so.keyDerivation.KeyBytes else {
            throw CryptoError.General.incorrectKeySize
        }
        
        guard let fileId = fileId, fileId.count > 0 else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        let header = Header(fileVersion: UInt8(Constants.CurrentFileVersion), fileId: fileId, headerVersion: UInt8(Constants.CurrentHeaderVersion), chunkSize: UInt32(bufSize), dataSize: UInt64(dataSize), symmetricKey:symmetricKey, fileType: UInt8(fileType), fileName: filename, videoDuration: UInt32(videoDuration))
        return header
    }
    
    private func writeHeader(output:OutputStream, header:Header, publicKey:Bytes?) throws  {
        // File beggining - 2 bytes
        var numWritten = output.write(Constants.FileBeggining.bytes, maxLength: Constants.FileBegginingLen)

        // File version number - 1 byte
        numWritten += output.write([UInt8(Constants.CurrentFileVersion)], maxLength: Constants.FileFileVersionLen)

        // File ID - 32 bytes
        numWritten += output.write(header.fileId, maxLength: Constants.FileFileIdLen)

        guard let publicKey = publicKey else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        let headerBytes = toBytes(header:header)
        
        guard let encHeader = so.box.seal(message: headerBytes, recipientPublicKey: publicKey) else {
            throw CryptoError.Internal.sealFailure
        }

        // Write header size - 4 bytes
        numWritten += output.write(Crypto.toBytes(value: encHeader.count), maxLength: Constants.FileHeaderSizeLen)
        
        // Write header
        numWritten += output.write(encHeader, maxLength: encHeader.count)
        guard numWritten ==  (Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Constants.FileHeaderSizeLen + encHeader.count) else {
            output.write([], maxLength: 0)
            throw CryptoError.IO.writeFailure
        }
    }
        
    private func getFileHeader(input:InputStream) throws -> Header? {
        
        var buf:Bytes = Bytes(repeating: 0, count: Constants.FileHeaderBeginningLen)
        guard Constants.FileHeaderBeginningLen == input.read(&buf, maxLength: Constants.FileHeaderBeginningLen) else {
            throw CryptoError.IO.readFailure
        }
        var offset:Int = 0
        let fileBegginingStr:String = String(bytes: Bytes(buf[offset..<(offset + Constants.FileBegginingLen)]), encoding: String.Encoding.utf8) ?? ""
        if fileBegginingStr != Constants.FileBeggining {
            throw CryptoError.Header.incorrectFileBeggining
        }
        offset += Constants.FileBegginingLen
        
        let fileVersion:UInt8 = buf[2]
        if fileVersion != Constants.CurrentFileVersion {
            throw CryptoError.Header.incorrectFileVersion
        }
        offset += 1
        
        let fileId:Bytes = Bytes(buf[offset..<offset + Constants.FileFileIdLen])
        offset += Constants.FileFileIdLen
        
        let headerSize:UInt32 = Crypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
        offset += Constants.FileHeaderSizeLen
        guard headerSize > 0 else {
            throw CryptoError.Header.incorrectHeaderSize
        }

        var header:Header = Header()
        header.overallHeaderSize = 0

        header.fileId = fileId
        header.fileVersion = fileVersion
        header.headerSize = headerSize
        header.overallHeaderSize! += UInt32(Constants.FileBegginingLen) + UInt32(Constants.FileFileVersionLen) + UInt32(Constants.FileFileIdLen) + UInt32(Constants.FileHeaderSizeLen) + headerSize
        
        var encHeaderBytes = Bytes(repeating: 0, count: Int(headerSize))
        let numRead = input.read(&encHeaderBytes, maxLength: Int(headerSize))
        guard headerSize ==  numRead else {
            throw CryptoError.IO.readFailure
        }
        
        let publicKey = try readPrivateFile(filename: Constants.PublicKeyFilename)
        
        //TODO : Get Secret key from memory 
        let privateKey:Bytes = try getPrivateKey(password: "11111111")
        
        guard let headerBytes = so.box.open(anonymousCipherText: encHeaderBytes, recipientPublicKey: publicKey, recipientSecretKey: privateKey) else {
            throw CryptoError.Internal.openlFailure
        }
        
        offset = 0
        header.headerVersion = headerBytes[offset]
        offset += 1
        
        header.chunkSize = Crypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileChunksizeLen]))
        offset += Constants.FileChunksizeLen
        
        header.dataSize = Crypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileDataSizeLen]))
        offset += Constants.FileDataSizeLen
        
        header.symmetricKey = Bytes(headerBytes[offset..<offset + so.keyDerivation.KeyBytes])
        offset += so.keyDerivation.KeyBytes
        
        header.fileType = headerBytes[offset]
        offset += 1
        
        let fileNameSize:Int = Crypto.fromBytes(b:Bytes(headerBytes[offset..<offset + Constants.FileNameSizeLen]))
        offset += Constants.FileNameSizeLen
        header.fileName = String(bytes: Bytes(headerBytes[offset..<offset + fileNameSize]), encoding: String.Encoding.utf8) ?? ""
        
        offset += fileNameSize
        header.videoDuration = Crypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileVideoDurationlen]))
        
        return header
    }
    
    public func encryptFile(input:InputStream, output:OutputStream, filename:String, fileType:Int, dataLength:UInt, fileId:Bytes?, videoDuration:Int) throws -> Bytes {
        
        let publicKey = try readPrivateFile(filename: Constants.PublicKeyFilename);
        let symmetricKey = so.keyDerivation.key()
        
        guard let fileId = so.randomBytes.buf(length: Constants.FileFileIdLen) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        
        let header = try getNewHeader(symmetricKey: symmetricKey, dataSize: dataLength, filename: filename, fileType: fileType, fileId: fileId, videoDuration: videoDuration)
        try writeHeader(output: output, header: header, publicKey: publicKey)
        _ = try encryptData(input: input, output: output, header: header)
        
        return fileId;
    }

    private func encryptData(input:InputStream, output:OutputStream, header:Header?) throws -> Bool {
        guard let header = header, (1...bufSize).contains(Int(header.chunkSize)) else {
            throw CryptoError.Header.incorrectChunkSize
        }

        let contextBytes:Bytes = Constants.XCHACHA20POLY1305_IETF_CONTEXT.bytes
        var chunkNumber:UInt64 = 1

        var buf:Bytes = []
        var numRead = 0
        var diff:Int = 0

        var numWrite:Int = 0
          repeat {
            buf = Bytes(repeating: 0, count: Int(header.chunkSize))
            numRead = input.read(&buf, maxLength: buf.count)
            assert(numRead >= 0)
            diff = Int(header.chunkSize) - numRead
            assert(diff >= 0)
            if diff > 0 {
                buf = Bytes(buf[..<numRead])
            }
            let keyBytesLength = so.aead.xchacha20poly1305ietf.KeyBytes
            guard let chunkKey = so.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: keyBytesLength, context: Constants.XCHACHA20POLY1305_IETF_CONTEXT) else {
                throw CryptoError.Internal.keyDerivationFailure
            }
            guard chunkKey.count == so.aead.xchacha20poly1305ietf.KeyBytes else {
                throw CryptoError.General.incorrectKeySize
            }
            guard let (authenticatedCipherText, chunkNonce) : (Bytes, Bytes)  = so.aead.xchacha20poly1305ietf.encrypt(message: buf, secretKey: chunkKey, additionalData: contextBytes) else {
                throw CryptoError.General.incorrectKeySize
            }
            numWrite = output.write(chunkNonce, maxLength: chunkNonce.count)
            assert(numWrite == chunkNonce.count)
            numWrite = output.write(authenticatedCipherText, maxLength:authenticatedCipherText.count)
            assert(numWrite == authenticatedCipherText.count)
            chunkNumber += UInt64(1)
         } while (diff == 0)

         output.close();
         input.close();
         return true;
    }
        
    
    public func decryptFile(input:InputStream, output:OutputStream) throws -> Bool {
        let header = try getFileHeader(input:input)
        _ = try decryptData(input: input, output: output, header: header)
        return true
    }

    private func decryptData(input:InputStream, output:OutputStream, header:Header?) throws -> Bool {
            guard let header = header, (1...bufSize).contains(Int(header.chunkSize)) else {
                throw CryptoError.Header.incorrectChunkSize
            }
            
            let contextBytes:Bytes = Constants.XCHACHA20POLY1305_IETF_CONTEXT.bytes
            var chunkNumber:UInt64 = 1

            let dataReadSize:Int = Int(header.chunkSize) + so.aead.xchacha20poly1305ietf.ABytes + so.aead.xchacha20poly1305ietf.NonceBytes
            var buf:Bytes = Bytes(repeating: 0, count: dataReadSize)
            var numRead = 0
            var diff:Int = 0
            
            var numWrite:Int = 0
                    repeat {
                        numRead = input.read(&buf, maxLength: buf.count)
                        diff = dataReadSize - numRead
                        if diff > 0 {
                           buf = buf.dropLast(diff)
                        }
                        let keyBytesLength = so.aead.xchacha20poly1305ietf.KeyBytes
                        guard let chunkKey = so.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: keyBytesLength, context: Constants.XCHACHA20POLY1305_IETF_CONTEXT) else {
                            throw CryptoError.Internal.keyDerivationFailure
                        }
                        assert(keyBytesLength == chunkKey.count)
                        guard let  decryptedData = so.aead.xchacha20poly1305ietf.decrypt(nonceAndAuthenticatedCipherText: buf, secretKey: chunkKey, additionalData: contextBytes) else {
                            throw CryptoError.Internal.decrypFailure
                        }
                        assert(header.chunkSize == decryptedData.count || (diff != 0))
                        numWrite = output.write(decryptedData, maxLength: decryptedData.count)
                        assert(numWrite == decryptedData.count)
                        chunkNumber += UInt64(1)
                   } while (diff == 0)
                   output.close();
                   input.close();
                   return true;
    }
    
    private func savePrivateFile(filename:String, data:Bytes?) throws -> Bool {
     
        guard let fullPath = SPFileManager.fullPathOfFile(fileName: filename) else {
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
    
    private func readPrivateFile(filename:String ) throws -> Bytes {
        
        guard let fullPath = SPFileManager.fullPathOfFile(fileName: filename) else {
            throw CryptoError.PrivateFile.invalidPath
        }
        guard let input:InputStream = InputStream(url: fullPath) else {
            throw CryptoError.IO.readFailure
        }
        input.open()
        
        var buffer = Bytes(repeating: 0, count: pivateBufferSize)
        var numRead:Int = 0
        var outBuff = Bytes(repeating: 0, count: 0)
        
        repeat {
            numRead = input.read(&buffer, maxLength: pivateBufferSize)
            outBuff += buffer[0..<numRead]
        } while (numRead > 0)
        
        if outBuff.count <= 0 {
            throw CryptoError.IO.readFailure
        }
        input.close()
        return outBuff
    }
    
    public struct SPFile {
        public var header:Header?
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
        public func toString() -> String {
            return "Chunk Size - \(chunkSize)\n" + "Data Size - \(dataSize)\n" +
                    "Symmetric Key - \(Crypto.byteArrayToBase64(data: symmetricKey))\n" +
                    "File Type - \(fileType)\n" +
                    "Filename - \(fileName ?? "")\n\n" +
                    "Video Duration - \(videoDuration)\n\n"
        }
        
    }
}

extension Crypto {

        public static func toBytes<T:FixedWidthInteger>(value:T) -> Bytes {
            var result:Bytes = []
            let numOfBytes = MemoryLayout<T>.size
            if numOfBytes == 1 {
                return [UInt8(value)]
            }
            var shift = 0
            for index in (0...numOfBytes - 1) {
                shift = 8 * index
                let val:UInt8 = UInt8((value >> shift) & 255)
                result.append(val)
            }
            return result
        }
        
        public static func fromBytes<T:FixedWidthInteger>(b:Bytes) -> T  {
            assert(0 != b.count)
            if b.count == 1 {
                return T(b[0] & 255)
            }

            var result:T = T(0)
            var shift = 0
            for index in (0...b.count - 1) {
                shift = 8 * index
                result |= T(b[index] & 255) << shift
            }
            return result
        }
            
        public static func byteArrayToBase64(data:Bytes) -> String {
            assert(data.count > 0)
            let newData = Data(data)
            return newData.base64EncodedString()
        }
        
    public func toBytes(header:Header) -> Bytes {
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
                headerBytes += Crypto.toBytes(value: bytes.count)
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
            header.symmetricKey = Bytes(data[offset..<so.keyDerivation.KeyBytes])
            offset += so.keyDerivation.KeyBytes
            header.fileType = data[offset]
            offset += Constants.FileTypeLen
            let fileNameSize:Int = Crypto.fromBytes(b:Bytes(data[offset..<offset + Constants.FileNameSizeLen]))
            offset += Constants.FileNameSizeLen
            header.fileName = String(bytes: Bytes(data[offset..<offset + fileNameSize]), encoding: String.Encoding.utf8) ?? ""
            offset += fileNameSize
            header.videoDuration = Crypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileVideoDurationlen]))
            return header
            }
}
