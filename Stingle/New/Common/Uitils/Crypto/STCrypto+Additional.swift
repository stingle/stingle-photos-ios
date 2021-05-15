//
//  STCrypto+Additional.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/20/21.
//

import Sodium
import UIKit

extension STCrypto {
    
    func decrypt(fromUrl: URL, toUrl: URL, header: STHeader?, validateHeader: Bool = true) throws {
        guard let output = OutputStream(url: toUrl, append: true), let input = InputStream(url: fromUrl)  else {
            throw CryptoError.General.creationFailure
        }
        defer {
            input.close()
            output.close()
        }
        input.open()
        output.open()
        try self.decryptFile(input: input, output: output, header: header, validateHeader: validateHeader)
    }
            
    func decryptData(data: Data, header: STHeader?, validateHeader: Bool = true) throws -> Data {
                
        let output = OutputStream(toMemory: ())
        let input = InputStream(data: data)
                
        defer {
            input.close()
            output.close()
        }
        
        input.open()
        output.open()
        
        try self.decryptFile(input: input, output: output, header: header, validateHeader: validateHeader)
        let result = output.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
        
        guard let resultData = result else {
            throw CryptoError.General.unknown
        }
        
        return resultData
    }
    
    func encryptData(data: Data, header: STHeader) throws -> Data {
        let output = OutputStream(toMemory: ())
        let input = InputStream(data: data)
        output.open()
        input.open()
        let publicKey = try self.readPrivateFile(filename: Constants.PublicKeyFilename)
        var bytes = try self.writeHeader(output: output, header: header, publicKey: publicKey)
        let encryptBytes = try self.encryptData(input: input, output: output, header: header)
        bytes.append(contentsOf: encryptBytes)
        input.close()
        output.close()
        
        return Data(bytes)
    }
    
    func createEncryptedFile(oreginalUrl: URL, thumbImage: Data, fileType: STHeader.FileType, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: Int32, publicKey: Bytes? = nil) throws -> (fileName: String, thumbUrl: URL, originalUrl: URL, headers: String) {
                
        let fileName = try self.createEncFileName()
        let fileId = try self.createNewFileId()
        let inputThumb = InputStream(data: thumbImage)
        inputThumb.open()
        let thumbUrl = toThumbUrl.appendingPathComponent(fileName)
        guard let outputThumb = OutputStream(toFileAtPath: thumbUrl.path, append: true) else {
            throw CryptoError.General.creationFailure
        }
        outputThumb.open()
        
        guard let inputOrigin = InputStream(fileAtPath: oreginalUrl.path) else {
            throw CryptoError.General.creationFailure
        }
        inputOrigin.open()
        
        let originalUrl = toUrl.appendingPathComponent(fileName)
        guard let outputOrigin = OutputStream(toFileAtPath: originalUrl.path, append: false) else {
            throw CryptoError.General.creationFailure
        }
        outputOrigin.open()
        defer {
            inputThumb.close()
            outputThumb.close()
            inputOrigin.close()
            outputOrigin.close()
        }
        
        let orgFileName = oreginalUrl.lastPathComponent
        
        let thumbHeader = try self.encryptFile(input: inputThumb, output: outputThumb, filename: orgFileName, fileType: fileType.rawValue, dataLength: UInt(thumbImage.count), fileId: fileId, videoDuration: UInt32(duration), publicKey: publicKey)
        
        let originHeader = try self.encryptFile(input: inputOrigin, output: outputOrigin, filename: orgFileName, fileType: fileType.rawValue, dataLength: UInt(fileSize), fileId: fileId, videoDuration: UInt32(duration), publicKey: publicKey)
                
        guard let base64Original = self.bytesToBase64Url(data: originHeader.encriptedHeader), let base64Thumb = self.bytesToBase64Url(data: thumbHeader.encriptedHeader) else {
            throw CryptoError.Header.incorrectHeader
        }
        let headers = base64Original + "*" + base64Thumb
        return (fileName, thumbUrl, originalUrl, headers)
    }
    
    func createEncFileName() throws -> String {
        let crypto = STApplication.shared.crypto
        guard let randData = crypto.getRandomBytes(lenght: STCrypto.Constants.FileNameLen), let base64Str = crypto.bytesToBase64Url(data: randData) else {
            throw CryptoError.General.creationFailure
        }
        
        return base64Str.appending(STCrypto.Constants.FileExtension)
    }
    
    func createNewFileId() throws -> Bytes {
        guard let fileId = self.newFileId() else {
            throw CryptoError.General.creationFailure
        }
        return fileId
    }
    
    func fileModificationDate(url: URL) -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    func encryptParamsForServer(params: [String: Any?]) throws -> String {
        let spbk  = try self.getServerPublicKey()
        guard let pks = KeyManagement.key else {
            throw CryptoError.Bundle.pivateKeyIsEmpty
        }
        let json = try JSONSerialization.data(withJSONObject: params)
        let res = try self.encryptCryptoBox(message: (Bytes)(json), publicKey: spbk, privateKey: pks)
        
        guard let base64 = self.bytesToBase64(data: res) else {
            throw CryptoError.General.creationFailure
        }
        
        return base64
    }
    
}
