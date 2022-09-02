//
//  STCrypto+Album.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/14/21.
//

import Sodium
import Foundation

extension STCrypto {
    
    //MARK: - Decryption
    
    func decryptAlbum(albumPKStr: String, encAlbumSKStr: String, metadataStr: String) throws -> STLibrary.Album.AlbumMetadata {
        guard let albumPK = self.base64ToByte(encodedStr: albumPKStr),
              let encAlbumSK = self.base64ToByte(encodedStr: encAlbumSKStr)
              else {
            throw CryptoError.Bundle.pivateKeyIsEmpty
        }
        guard let privateKey = STKeyManagement.key else {
            throw CryptoError.Bundle.pivateKeyIsEmpty
        }
        let publicKey = try self.readPrivateFile(fileName: Constants.PublicKeyFilename)
        
        
        guard let albumSK = self.sodium.box.open(anonymousCipherText: encAlbumSK, recipientPublicKey: publicKey, recipientSecretKey: privateKey) else {
            throw CryptoError.Internal.openFailure
        }
        
        let name = try self.parseAlbumMetadata(metadataStr: metadataStr, albumSK: albumSK, albumPK: albumPK)
        let result = STLibrary.Album.AlbumMetadata(name: name, publicKey: albumPK, privateKey: albumSK)
        return result
    }
    
    private func parseAlbumMetadata(metadataStr: String, albumSK: Bytes, albumPK: Bytes) throws -> String {
        
        guard let encMetadata = self.base64ToByte(encodedStr: metadataStr)  else {
            throw CryptoError.Internal.openFailure
        }
        
        guard let metadataBytes = self.sodium.box.open(anonymousCipherText: encMetadata, recipientPublicKey: albumPK, recipientSecretKey: albumSK) else {
            throw CryptoError.Internal.openFailure
        }
        
        let data = Data(metadataBytes)
        let input = InputStream(data: data)
        input.open()
        
        defer {
            input.close()
        }
        
        var buf:Bytes = [0]
        let metadataVersion = input.read(&buf, maxLength: Constants.CurrentAlbumMedadataVersionLen)
        
        guard metadataVersion == Constants.CurrentAlbumMedadataVersion else {
            throw CryptoError.Album.incorrectFileVersion
        }
        
        var albumNameSizeBytes = Bytes(repeating: 0, count: 4)
        input.read(&albumNameSizeBytes, maxLength: 4)
        
        let albumNameSize: Int =  Self.fromBytes(b: albumNameSizeBytes)
        guard albumNameSize > 0 || albumNameSize > Constants.MAX_BUFFER_LENGTH else {
            return ""
        }
        var albumNameBytes = Bytes(repeating: 0, count: albumNameSize)
        input.read(&albumNameBytes, maxLength: albumNameSize)
        let nameData = Data(albumNameBytes)
        let name = String(data: nameData, encoding: .utf8) ?? ""
        return name
    }
    
    
    //MARK: - Encryption
    
    func generateEncryptedAlbumDataAndID(albumName: String) throws -> (encPrivateKey: String, publicKey: String, metadata: String, albumID: String) {
        guard let bytesID =  self.getRandomBytes(lenght: Constants.AlbumIDLen), let albumID = self.bytesToBase64(data: bytesID) else {
            throw CryptoError.Internal.randomBytesGenerationFailure
        }
        let metadata = try self.generateEncryptedAlbumData(albumName: albumName)
        return (metadata.encPrivateKey, metadata.publicKey, metadata.metadata, albumID)
    }
    
    func generateEncryptedAlbumData(albumName: String) throws -> (encPrivateKey: String, publicKey: String, metadata: String) {
        let userPK = try self.readPrivateFile(fileName: Constants.PublicKeyFilename)
        let keyPair = self.sodium.box.keyPair()
        guard let albumSK = keyPair?.secretKey, let albumPK = keyPair?.publicKey else {
            throw CryptoError.Internal.keyPairGenerationFailure
        }
        let encryptedMetadata = try self.encryptAlbumMetadata(albumPK: albumPK, albumName: albumName)
        let encryptedSK = try self.encryptAlbumSK(albumSK: albumSK, userPK: userPK)
        
        guard let encPrivateKey = self.bytesToBase64(data: encryptedSK), let publicKey = self.bytesToBase64(data: albumPK), let metadata = self.bytesToBase64(data: encryptedMetadata) else {
            throw CryptoError.General.creationFailure
        }
                
        return (encPrivateKey, publicKey, metadata)
    }
    
    func encryptAlbumSK(albumSK: Bytes, userPK: Bytes) throws -> Bytes {
        guard let enc = self.sodium.box.seal(message: albumSK, recipientPublicKey: userPK) else {
            throw CryptoError.Internal.sealFailure
        }
        return enc
    }
    
    func encryptAlbumMetadata(albumPK: Bytes, albumName: String) throws -> Bytes  {
        let metadataByteStream = OutputStream(toMemory: ())
        metadataByteStream.open()
        defer {
            metadataByteStream.close()
        }
        metadataByteStream.write([UInt8(Constants.CurrentFileVersion)], maxLength: Constants.CurrentAlbumMedadataVersionLen)
        let albumNameBytes = albumName.bytes
        let count4: UInt32 = UInt32(albumName.count)
        let count: Bytes = STCrypto.toBytes(value: count4)
        metadataByteStream.write(count, maxLength: count.count)
        metadataByteStream.write(albumNameBytes, maxLength: albumNameBytes.count)
        guard let metadataData = metadataByteStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            throw CryptoError.IO.writeFailure
        }
        let metadataBytes = Bytes(metadataData)
        guard let enc = self.sodium.box.seal(message: metadataBytes, recipientPublicKey: albumPK) else {
            throw CryptoError.Internal.sealFailure
        }
        return enc
    }

}

public extension STLibrary.Album {
    
    struct AlbumMetadata: Equatable {
        
        public let name: String
        public let publicKey: Bytes
        public let privateKey: Bytes
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name
        }
    }
    
}
