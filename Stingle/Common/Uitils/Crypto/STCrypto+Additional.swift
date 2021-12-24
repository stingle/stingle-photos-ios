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
    
    func createEncryptedFile(oreginalUrl: URL, thumbImage: Data, fileType: STHeader.FileType, duration: TimeInterval, toUrl: URL, toThumbUrl: URL, fileSize: UInt, publicKey: Bytes? = nil) throws -> (fileName: String, thumbUrl: URL, originalUrl: URL, headers: String) {
                
        let fileName = try self.createEncFileName()
        let fileId = try self.createNewFileId()
        let inputThumb = InputStream(data: thumbImage)
        inputThumb.open()
        let thumbUrl = toThumbUrl.appendingPathComponent(fileName)
        guard let outputThumb = OutputStream(toFileAtPath: thumbUrl.path, append: true) else {
            inputThumb.close()
            throw CryptoError.General.creationFailure
        }
        outputThumb.open()
        
        guard let inputOrigin = InputStream(fileAtPath: oreginalUrl.path) else {
            inputThumb.close()
            outputThumb.close()
            throw CryptoError.General.creationFailure
        }
        inputOrigin.open()
        
        let originalUrl = toUrl.appendingPathComponent(fileName)
        guard let outputOrigin = OutputStream(toFileAtPath: originalUrl.path, append: false) else {
            inputThumb.close()
            outputThumb.close()
            inputOrigin.close()
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
    
    func encryptParamsForServer(params: [String: Any?], serverPK: Bytes? = nil, privateKey: Bytes? = nil) throws -> String {
        
        var serverPK: Bytes? = serverPK
        if serverPK == nil {
            serverPK = try self.getServerPublicKey()
        }
        
        var privateKey: Bytes? = privateKey
        if privateKey == nil {
            privateKey = STKeyManagement.key
        }
        
        guard let pks = privateKey, let spbk = serverPK else {
            throw CryptoError.Bundle.pivateKeyIsEmpty
        }
        let json = try JSONSerialization.data(withJSONObject: params)
        let res = try self.encryptCryptoBox(message: (Bytes)(json), publicKey: spbk, privateKey: pks)
        
        guard let base64 = self.bytesToBase64(data: res) else {
            throw CryptoError.General.creationFailure
        }
        
        return base64
    }
    
    func decryptData(fileReader: STFileReader, header: STHeader, fromOffSet: off_t, length: Int, queue: DispatchQueue = .main, completionHandler: @escaping (Data?, Error?) -> Void) {
        
        guard let headerSize = header.headerSize, headerSize > 0, header.chunkSize >= 1 && header.chunkSize < Constants.MAX_BUFFER_LENGTH else {
            completionHandler(nil, CryptoError.Header.incorrectHeaderSize)
            return
        }
        
        let startOffSet = off_t(Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Int(headerSize) + Constants.FileHeaderSizeLen)
        let dataReadSize: off_t = off_t(header.chunkSize) + off_t(self.sodium.aead.xchacha20poly1305ietf.ABytes + self.sodium.aead.xchacha20poly1305ietf.NonceBytes)
        
        var fromOffSetRead = fromOffSet
        let fromOffSetIndex = Int64(floor(Double(fromOffSet) / Double(dataReadSize)))
        fromOffSetRead = fromOffSetIndex * dataReadSize + startOffSet
        
        var toOffSetRead = fromOffSet + off_t(length)
        let toOffSetReadIndex = Int64(ceil(Double(toOffSetRead) / Double(dataReadSize)))
        toOffSetRead = toOffSetReadIndex * dataReadSize + startOffSet
        toOffSetRead = min(toOffSetRead, off_t(fileReader.fullSize))
        let range = CountableRange<off_t>(uncheckedBounds: (fromOffSetRead, toOffSetRead))
        
        let firstDiff = (fromOffSet + startOffSet -  fromOffSetRead)                
        fileReader.read(byteRange: range, queue: queue) { [weak self] data in
            guard let weakSelf = self, let data = data else {
                completionHandler(nil, CryptoError.IO.readFailure)
                return
            }
            
            if data.count == .zero {
                print(range)
            }
            var chunkIndex = fromOffSetIndex
            let bytes = Bytes(data)
            var result = Bytes()
            while chunkIndex < toOffSetReadIndex {
                let chunkIndexWtthOuthHeader = chunkIndex - fromOffSetIndex
                let from = chunkIndexWtthOuthHeader * dataReadSize
                let to = (chunkIndexWtthOuthHeader + 1) * dataReadSize
                let chunk = bytes.copyMemory(fromIndex: Int(from), toIndex: Int(to))
                do {
                    let decryptChunk = try weakSelf.decryptChunk(chunkData: chunk, chunkNumber: UInt64(chunkIndex + 1), header: header)
                    result.append(contentsOf: decryptChunk)
                } catch {
                    completionHandler(nil, error)
                    return
                }
                chunkIndex = chunkIndex + 1
            }
            
            let lastDiff = Int(firstDiff) + length
            result = result.copyMemory(fromIndex: Int(firstDiff), toIndex: Int(lastDiff))
            let resultData = Data(result)
            completionHandler(resultData, nil)
        }
        
    }
    
    func decryptDataChunkIndex(fileReader: STFileReader, header: STHeader, chunkIndex: Int, queue: DispatchQueue = .main, completionHandler: @escaping (Data?, Error?) -> Void) {
        self.readChunk(fileReader: fileReader, header: header, chunkIndex: chunkIndex) { [weak self] bytes, error in
            guard let weakSelf = self, let bytes = bytes else {
                completionHandler(nil, CryptoError.IO.readFailure)
                return
            }
            
            do {
                let result = try weakSelf.decryptChunk(chunkData: bytes, chunkNumber: UInt64(chunkIndex + 1), header: header)
                let resultData = Data(result)
                completionHandler(resultData, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }
    
    func readChunk(fileReader: STFileReader, header: STHeader, chunkIndex: Int, queue: DispatchQueue = .main, completionHandler: @escaping (Bytes?, Error?) -> Void)  {
        
        guard let headerSize = header.headerSize, headerSize > 0, header.chunkSize >= 1 && header.chunkSize < Constants.MAX_BUFFER_LENGTH else {
            completionHandler(nil, CryptoError.Header.incorrectHeaderSize)
            return
        }
        
        let dataReadSize: Int = Int(header.chunkSize) + self.sodium.aead.xchacha20poly1305ietf.ABytes + self.sodium.aead.xchacha20poly1305ietf.NonceBytes
        
        var startOffset = off_t(Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Int(headerSize) + Constants.FileHeaderSizeLen)
                
        startOffset = startOffset + off_t(chunkIndex) * off_t(dataReadSize)
        startOffset = min(startOffset, off_t(header.dataSize))
        var endOffset = startOffset + off_t(dataReadSize)
        
        endOffset = min(endOffset, off_t(header.dataSize))
                
        let range = CountableRange<off_t>(uncheckedBounds: (startOffset, endOffset))
                        
        fileReader.read(byteRange: range, queue: queue) { dispatchData in
            guard let dispatchData = dispatchData else {
                completionHandler(nil, CryptoError.IO.readFailure)
                return
            }
            let data = Data(copying: dispatchData)
            let bytes = Bytes(data)
            completionHandler(bytes, nil)
        }
        
    }
    
    func chunkSizeForHeader(header: STHeader) -> UInt64 {
        let dataReadSize: UInt64 = UInt64(header.chunkSize) + UInt64(self.sodium.aead.xchacha20poly1305ietf.ABytes + self.sodium.aead.xchacha20poly1305ietf.NonceBytes)
        return dataReadSize
    }
    
    func startOffSet(header: STHeader) -> UInt64 {
        guard self.isValid(header: header) else {
            return .zero
        }
        let startOffSet = UInt64(Constants.FileBegginingLen + Constants.FileFileVersionLen + Constants.FileFileIdLen + Int(header.headerSize ?? .zero) + Constants.FileHeaderSizeLen)
        return startOffSet
    }
    
    func isValid(header: STHeader) -> Bool {
        guard let headerSize = header.headerSize, headerSize > 0, header.chunkSize >= 1 && header.chunkSize < Constants.MAX_BUFFER_LENGTH else {
            return false
        }
        return true
    }
    
    func getRandomString(length: Int) -> String? {
        guard let random = self.getRandomBytes(lenght: length) else {
            return nil
        }
        return self.bytesToBase64(data: random)
    }
    
}
