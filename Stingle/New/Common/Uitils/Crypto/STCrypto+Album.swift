//
//  STCrypto+Album.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/14/21.
//

import Sodium

extension STCrypto {
    
    func decryptAlbum(albumPKStr: String, encAlbumSKStr: String, metadataStr: String) throws -> STLibrary.Album.AlbumMetadata {
        guard let albumPK = self.base64ToByte(encodedStr: albumPKStr),
              let encAlbumSK = self.base64ToByte(encodedStr: encAlbumSKStr)
              else {
            throw CryptoError.Bundle.pivateKeyIsEmpty
        }
        guard let privateKey = KeyManagement.key else {
            throw CryptoError.Bundle.pivateKeyIsEmpty
        }
        let publicKey = try self.readPrivateFile(filename: Constants.PublicKeyFilename)
        
        
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
        let metadataVersion = input.read(&buf, maxLength: 1)
        
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
    

}

extension STLibrary.Album {
    
    struct AlbumMetadata: Equatable {
        let name: String
        let publicKey: Bytes
        let privateKey: Bytes
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name
        }
    }
    
}
