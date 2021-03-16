//
//  Crypto+Header.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Sodium
import Clibsodium

struct STHeaders {
    let file: STHeader?
    let thumb: STHeader?
}

struct STHeader {
    
    public var fileVersion: UInt8 = 0
    public var fileId: Bytes = []
    public var headerSize: UInt32?
    public var headerVersion: UInt8 = 0
    public var chunkSize: UInt32 = 0
    public var dataSize: UInt64 = 0
    public var symmetricKey: Bytes = []
    public var fileType: UInt8 = 0
    public var fileName: String?
    public var videoDuration: UInt32 = 0
    public var overallHeaderSize: UInt32?
    
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

extension STCrypto {
    
    func fromBytes(data: Bytes) -> STHeader {
        var header = STHeader()
        var offset:Int = 0
        header.headerVersion = data[0]
        offset += Constants.HeaderVersionLen
        header.chunkSize = STCrypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileChunksizeLen]))
        offset += Constants.FileChunksizeLen
        header.dataSize = STCrypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileDataSizeLen]))
        offset += Constants.FileDataSizeLen
        header.symmetricKey = Bytes(data[offset..<sodium.keyDerivation.KeyBytes])
        offset += sodium.keyDerivation.KeyBytes
        header.fileType = data[offset]
        offset += Constants.FileTypeLen
        let fileNameSize:Int = STCrypto.fromBytes(b:Bytes(data[offset..<offset + Constants.FileNameSizeLen]))
        offset += Constants.FileNameSizeLen
        header.fileName = String(bytes: Bytes(data[offset..<offset + fileNameSize]), encoding: String.Encoding.utf8) ?? ""
        offset += fileNameSize
        header.videoDuration = STCrypto.fromBytes(b: Bytes(data[offset..<offset + Constants.FileVideoDurationlen]))
        return header
    }
    
    func decryptData(data: Bytes, header: STHeader?, chunkNumber: UInt64, completionHandler:  @escaping (Bytes?) -> Swift.Void) throws -> Bool {
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
    func decryptData(input:InputStream, header:STHeader?, completionHandler:  @escaping (Bytes?) -> Swift.Void) throws -> Bool {
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
    
    private func decryptChunk(chunkData: Bytes, chunkNumber: UInt64, header: STHeader) throws -> Bytes {
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
    
    func getHeaders(file: STLibrary.File) -> STHeaders  {
        
        var fileHeader: STHeader?
        var thumbHeader: STHeader?
        
        let headers = file.headers
        let hdrs = headers.split(separator: "*")
        let crypto = STApplication.shared.crypto
        
        hdrs.enumerated().forEach { (index, hdr) in
            let st = self.base64urlToBase64(base64urlString:String(hdr))
            if let data = crypto.base64ToByte(encodedStr: st) {
                let input = InputStream(data: Data(data))
                input.open()
                do {
                    let header = try crypto.getFileHeader(input: input)
                    input.close()
                    switch index {
                    case 0:
                        fileHeader = header
                    case 1:
                        thumbHeader = header
                    default:
                        break
                    }
                } catch {
                    print(error)
                }
                input.close()
            }
        }
        return STHeaders(file: fileHeader, thumb: thumbHeader)
    }
    
    public func getFileHeaders(originalPath: String, thumbPath: String) throws -> String? {
        guard let originBytes = try self.getFileHeaderBytes(path: originalPath) else {
            return nil
        }
        guard let thumbBytes = try self.getFileHeaderBytes(path: thumbPath) else {
            return nil
        }

        return self.bytesToBase64(data: originBytes)! + "*" + self.bytesToBase64(data: thumbBytes)!
    }
    
    public func getFileHeaderBytes(path: String) throws -> Bytes? {
        guard let input = InputStream(fileAtPath: path) else {
            return nil
        }
        input.open()
        let overallHeaderSize = try self.getOverallHeaderSize(input: input)
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
        
        let headerSize:UInt32 = STCrypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
        offset += Constants.FileHeaderSizeLen
        guard headerSize > 0 else {
            throw CryptoError.Header.incorrectHeaderSize
        }
        offset += Int(headerSize)
        return offset
    }
    
    func getNewHeader(symmetricKey: Bytes?, dataSize: UInt, filename: String, fileType: Int, fileId: Bytes?, videoDuration: UInt32) throws  -> STHeader {
        guard  let symmetricKey = symmetricKey, symmetricKey.count == self.sodium.keyDerivation.KeyBytes else {
            throw CryptoError.General.incorrectKeySize
        }
        
        guard let fileId = fileId, fileId.count > 0 else {
            throw CryptoError.General.incorrectParameterSize
        }
        
        let header = STHeader(fileVersion: UInt8(Constants.CurrentFileVersion), fileId: fileId, headerVersion: UInt8(Constants.CurrentHeaderVersion), chunkSize: UInt32(bufSize), dataSize: UInt64(dataSize), symmetricKey:symmetricKey, fileType: UInt8(fileType), fileName: filename, videoDuration: UInt32(videoDuration))
        return header
    }
    
    func writeHeader(output: OutputStream, header: STHeader, publicKey: Bytes?) throws  {
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
        numWritten += output.write(STCrypto.toBytes(value: Int32(encHeader.count)), maxLength: Constants.FileHeaderSizeLen)
        
        // Write header3
        numWritten += output.write(encHeader, maxLength: encHeader.count)
        guard numWritten ==  (Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Constants.FileHeaderSizeLen + encHeader.count) else {
            throw CryptoError.IO.writeFailure
        }
    }
        
    func getFileHeader(input: InputStream) throws -> STHeader {
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
        
        let headerSize:UInt32 = STCrypto.fromBytes(b: Bytes((buf[offset..<offset + Constants.FileHeaderSizeLen])))
        offset += Constants.FileHeaderSizeLen
        guard headerSize > 0 else {
            throw CryptoError.Header.incorrectHeaderSize
        }
        
        var header:STHeader = STHeader()
        
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
        
        header.chunkSize = STCrypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileChunksizeLen]))
        offset += Constants.FileChunksizeLen
        
        header.dataSize = STCrypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileDataSizeLen]))
        offset += Constants.FileDataSizeLen
        
        header.symmetricKey = Bytes(headerBytes[offset..<offset + sodium.keyDerivation.KeyBytes])
        offset += sodium.keyDerivation.KeyBytes
        
        header.fileType = headerBytes[offset]
        offset += Constants.FileTypeLen
        
        let fileNameSize:Int = STCrypto.fromBytes(b:Bytes(headerBytes[offset..<offset + Constants.FileNameSizeLen]))
        offset += Constants.FileNameSizeLen
        header.fileName = String(bytes: Bytes(headerBytes[offset..<offset + fileNameSize]), encoding: String.Encoding.utf8) ?? ""
        
        offset += fileNameSize
        header.videoDuration = STCrypto.fromBytes(b: Bytes(headerBytes[offset..<offset + Constants.FileVideoDurationlen]))
        return header
    }
    
}
