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
    
    public func generateMainKeypair(password:String , privateKey:Bytes?, publicKey:Bytes?) throws{
        
        let pwdSalt:Bytes = so.randomBytes.buf(length: so.pwHash.SaltBytes) ?? []
        var result = savePrivateFile(filename: Constants.PwdSaltFilename, data: pwdSalt)
        
        if !result {
            //TODO: throw exception
            return
        }
        var newPrivateKey:Bytes?  = nil
        var newPublicKey:Bytes?  = nil

        if(privateKey == nil || publicKey == nil) {
            guard let keyPair = so.box.keyPair() else {
                //TODO: throw exception
                return
            }
            newPrivateKey = privateKey ?? keyPair.secretKey
            newPublicKey = publicKey ?? keyPair.publicKey
        }
        
        guard let pwdKey = try getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal) else {
            //TODO: throw exception
            return
        }
        
        guard let pwdEncNonce = so.randomBytes.buf(length: so.secretBox.NonceBytes) else {
            //TODO: throw exception
            return
        }
        result = savePrivateFile(filename: Constants.SKNONCEFilename, data: pwdEncNonce)
        if !result {
            //TODO: throw exception
            return
        }
        
        guard let encryptedPrivateKey = encryptSymmetric(key: pwdKey, nonce: pwdEncNonce, data: newPrivateKey) else {
            //TODO: throw exception
            return
        }
        
        result = savePrivateFile(filename: Constants.PrivateKeyFilename, data: encryptedPrivateKey)
        if !result {
            //TODO: throw exception
            return
        }
        
        result = savePrivateFile(filename: Constants.PublicKeyFilename, data: newPublicKey!)
        if !result {
            //TODO: throw exception
            return
        }
    }
    
    public func getPrivateKey(password:String) throws  -> Bytes? {
        guard let encKey = try getKeyFromPassword(password: password, difficulty: Constants.KdfDifficultyNormal) else {
            //TODO: throw exception
            return nil
        }
        
        guard let encPrivKey = readPrivateFile(filename: Constants.PrivateKeyFilename) else {
            //TODO throw exception
            return nil
        }
        
        guard let nonce = readPrivateFile(filename: Constants.SKNONCEFilename) else {
            //TODO throw exception
            return nil
        }
        
        return try decryptSymmetric(key:encKey, nonce:nonce, data:encPrivKey)
    }
        
    public func getKeyFromPassword(password:String, difficulty:Int) throws -> Bytes? {
        
        guard let salt = readPrivateFile(filename: Constants.PwdSaltFilename), salt.count == so.pwHash.SaltBytes else {
            //TODO: throw exception
            return nil
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
            // TODO: throw exception
            return nil
        }
        return key
    }
        
    private func encryptSymmetric(key:Bytes?, nonce:Bytes?, data:Bytes?) -> Bytes? {

        guard let key = key, key.count ==  so.secretBox.KeyBytes else {
            //TODO: throw exception
            return nil
        }
        
        guard let nonce = nonce, nonce.count == so.secretBox.NonceBytes else {
            //TODO: throw exception
            return nil
        }
        
        guard let data = data, data.count > 0 else {
            //TODO: throw exception
            return nil
        }
        
        guard let cypherText = so.secretBox.seal(message: data, secretKey: key, nonce: nonce) else {
            //TODO: throw exception
            return nil
        }
        
        return cypherText
    }
    
    private func decryptSymmetric(key:Bytes?, nonce:Bytes?, data:Bytes?) throws -> Bytes? {
        
        guard let key = key, key.count == so.secretBox.KeyBytes else {
            //TODO: throw exception
            return nil
        }
        
        guard let nonce = nonce, nonce.count == so.secretBox.NonceBytes else {
            //TODO: throw exception
            return nil
        }
        
        guard let data = data, data.count > 0 else {
            //TODO: throw exception
            return nil
        }
        
        guard let plainText = so.secretBox.open(authenticatedCipherText: data, secretKey: key, nonce: nonce) else {
            //TODO: throw exception
            return nil
        }
        
        return plainText
    }
    
    private func getNewHeader(symmetricKey:Bytes?, dataSize:UInt, filename:String, fileType:Int, fileId:Bytes?, videoDuration:Int) throws  -> Header? {
        guard  let symmetricKey = symmetricKey, symmetricKey.count == so.keyDerivation.KeyBytes else {
            //TODO: throw exception
            return nil

        }
        
        guard let fileId = fileId, fileId.count > 0 else {
            //TODO: throw exception
            return nil
        }
        
        let header = Header(fileVersion: UInt8(Constants.CurrentFileVersion), fileId: fileId, headerVersion: UInt8(Constants.CurrentHeaderVersion), chunkSize: UInt32(bufSize), dataSize: UInt64(dataSize), symmetricKey:symmetricKey, fileType: UInt8(fileType), fileName: filename, videoDuration: UInt32(videoDuration))
        return header
    }
    
    private func writeHeader(output:OutputStream, header:Header, publicKey:Bytes?) throws  {
        // File beggining - 2 bytes
        output.write(Constants.FileBeggining.bytes, maxLength: Constants.FileBegginingLen)

        // File version number - 1 byte
        output.write([UInt8(Constants.CurrentFileVersion)], maxLength: 1)

        // File ID - 32 bytes
        output.write(header.fileId, maxLength: header.fileId.count)

        guard let publicKey = publicKey, let headerBytes = toBytes(header:header) else {
            //TODO: Throw Exception
            return
        }
        guard let encHeader = so.box.seal(message: headerBytes, recipientPublicKey: publicKey) else {
            //TODO: Throw Exception
            return
        }

        // Write header size - 4 bytes
        output.write(Crypto.toBytes(value: encHeader.count), maxLength: 4)
        
        // Write header
        output.write(encHeader, maxLength: encHeader.count)
    }
        
    public func getFileHeader(input:InputStream) throws -> Header? {
        
        var buf:Bytes = Bytes(repeating: 0, count: Constants.FileHeaderBeginningLen)
        guard Constants.FileHeaderBeginningLen == input.read(&buf, maxLength: Constants.FileHeaderBeginningLen) else {
            //TODO: Throw Exception
            return nil
        }
        var offset:Int = 0
        let fileBegginingStr:String = String(bytes: Bytes(buf[offset..<(offset + Constants.FileBegginingLen)]), encoding: String.Encoding.utf8) ?? ""
        if fileBegginingStr != Constants.FileBeggining {
            //TODO: Throw Exception
            return nil
        }
        offset += Constants.FileBegginingLen
        
        let fileVersion:UInt8 = buf[2]
        if fileVersion != Constants.CurrentFileVersion {
            //TODO: Throw Exception
            return nil
        }
        offset += 1
        
        let fileId:Bytes = Bytes(buf[offset..<offset + Constants.FileFileIdLen])
        offset += Constants.FileFileIdLen
        
        let headerSize:UInt32 = Crypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
        offset += Constants.FileHeaderSizeLen
        guard headerSize > 0 else {
            //TODO: Throw Exception
            return nil
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
            //TODO: Throw Exception
            return nil
        }
        
        guard let publicKey = readPrivateFile(filename: Constants.PublicKeyFilename) else {
            //TODO: Throw Exception
            return nil
        }
        
        //TODO : Get Secret key from memory 
        guard let privateKey:Bytes = try getPrivateKey(password: "11111111") else {
            //TODO: Throw Exception
            return nil
        }
        
        guard let headerBytes = so.box.open(anonymousCipherText: encHeaderBytes, recipientPublicKey: publicKey, recipientSecretKey: privateKey) else {
            //TODO: Throw Exception
            return nil
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
        let publicKey = readPrivateFile(filename: Constants.PublicKeyFilename);
        let symmetricKey = so.keyDerivation.key()
        
        guard let fileId = so.randomBytes.buf(length: Constants.FileFileIdLen) else {
            //TODO: throw exception
            return []
        }
        
        guard let header = try getNewHeader(symmetricKey: symmetricKey, dataSize: dataLength, filename: filename, fileType: fileType, fileId: fileId, videoDuration: videoDuration) else {
            //TODO: throw exception
            return []
        }
        
        do {
            try writeHeader(output: output, header: header, publicKey: publicKey)
            _ = try encryptData(input: input, output: output, header: header)
        } catch {
                print("Some thing wrong")
        }
        return fileId;
    }

        
    public func getNewFileId() -> Bytes? {
        
        guard let fileId = so.randomBytes.buf(length: Constants.FileFileIdLen) else {
            //TODO: throw exception
            return nil
        }

        return fileId
    }
          
    private func encryptData(input:InputStream, output:OutputStream, header:Header?) throws  -> Bool {
        guard let header = header, (1...bufSize).contains(Int(header.chunkSize)) else {
            //TODO: throw exception
            return false
        }

        var chunkKey:Bytes = []
        var chunkNonce:Bytes = []
        var authenticatedCipherText:Bytes = []
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
            
            chunkKey = so.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: so.aead.xchacha20poly1305ietf.KeyBytes, context: Constants.XCHACHA20POLY1305_IETF_CONTEXT) ?? []
            assert(chunkKey.count == so.aead.xchacha20poly1305ietf.KeyBytes)
            
             (authenticatedCipherText, chunkNonce)  = so.aead.xchacha20poly1305ietf.encrypt(message: buf, secretKey: chunkKey, additionalData: contextBytes) ?? ([],[])
             numWrite = output.write(&chunkNonce, maxLength: chunkNonce.count)
             assert(numWrite == chunkNonce.count)
            
             numWrite = output.write(&authenticatedCipherText, maxLength:authenticatedCipherText.count)
             assert(numWrite == authenticatedCipherText.count)
             chunkNumber += UInt64(1)
         } while (diff == 0)

         output.close();
         input.close();
         return true;
    }
        
    
    public func decryptFile(input:InputStream, output:OutputStream) throws -> Bool {

        do {
            guard let header = try getFileHeader(input:input) else {
            //TODO: throw exception
            return false
        }
        let result = try decryptData(input: input, output: output, header: header)
            guard result == true else {
                //TODO: throw exception
                return false
            }
        } catch {
            return false
        }
        return true
    }

    private func decryptData(input:InputStream, output:OutputStream, header:Header?) throws -> Bool {
            guard let header = header, (1...bufSize).contains(Int(header.chunkSize)) else {
                //TODO: throw exception
                return false
            }
            
            var chunkKey:Bytes = []
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
                      chunkKey = so.keyDerivation.derive(secretKey: header.symmetricKey, index: chunkNumber, length: so.aead.xchacha20poly1305ietf.KeyBytes, context: Constants.XCHACHA20POLY1305_IETF_CONTEXT) ?? []
                      assert(so.aead.xchacha20poly1305ietf.KeyBytes == chunkKey.count)
                      
                      var decryptedData = so.aead.xchacha20poly1305ietf.decrypt(nonceAndAuthenticatedCipherText: buf, secretKey: chunkKey, additionalData: contextBytes) ?? []
                      assert(header.chunkSize == decryptedData.count || (diff != 0))
                      
                      numWrite = output.write(&decryptedData, maxLength: decryptedData.count)
                      assert(numWrite == decryptedData.count)
                      chunkNumber += UInt64(1)
                   } while (diff == 0)

                   output.close();
                   input.close();
                   return true;
    }
    
    private func savePrivateFile(filename:String, data:Bytes?) -> Bool {
     
        guard let fullPath = SPFileManager.fullPathOfFile(fileName: filename) else {
            // TODO: throw exception
            return false
        }

        guard let out = OutputStream(url: fullPath, append: false) else {
            // TODO: throw exception
            return false
        }
        out.open()
        
        guard let data = data else {
            // TODO: throw exception
            return false
        }
        let numWrite = out.write(data, maxLength: data.count)
        out.close()
        return numWrite == data.count
    }
    
    private func readPrivateFile(filename:String ) -> Bytes? {
        
        guard let fullPath = SPFileManager.fullPathOfFile(fileName: filename) else {
            // TODO: throw exception
            return nil
        }
        guard let input:InputStream = InputStream(url: fullPath) else {
            // TODO: throw exception
            return nil
        }
        input.open()
        
        var buffer = Bytes(repeating: 0, count: pivateBufferSize)
        var numRead:Int = 0
        var outBuff = Bytes(repeating: 0, count: 0)
        repeat {
            numRead = input.read(&buffer, maxLength: pivateBufferSize)
            outBuff += buffer[0..<numRead]
            print(numRead)
        } while (numRead > 0)
        
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
            let f:T = Crypto.fromBytes(b:result)
            print(value, f)
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
            
        public static func byteArrayToBase64(data:Bytes?) -> String {
            guard let data = data, data.count > 0 else {
                // TODO: throw exception
                return ""
            }
            let newData = Data(data)
            return newData.base64EncodedString()
        }
        
    public func toBytes(header:Header) -> Bytes? {
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
