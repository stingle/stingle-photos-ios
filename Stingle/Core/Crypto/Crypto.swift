//
//  Crypto.swift
//  Stingle
//
//  Created by Davit Grigoryan on 20.02.2020.
//  Copyright © 2020 Davit Grigoryan. All rights reserved.
//

import Foundation
import Sodium

enum FileType:Int {
    case FileTypeGeneral = 1
    case FileTypePhoto = 2
    case FileTypeVideo = 3
}

public class Crypto {

    private let so:Sodium
    public let FileBeggining:String = "SP"
    public let KeyFileBeggining:String = "SPK"
    public let CurrentFileVersion = 1
    public let CurrentHeaderVersion = 1
    public let CurrentKeyFileVersion = 1;

    public let PwdSaltFilename = "pwdSalt"
    public let SKNONCEFilename = "skNonce"
    public let PrivateKeyFilename = "private"
    public let PublicKeyFilename = "public"
    public let ServerPublicKeyFilename = "server_public"

    public let XCHACHA20POLY1305_IETF_CONTEXT = "__data__"
    public let MAX_BUFFER_LENGTH = 1024*1024*64;

    public let FileBegginingLen:Int
    public let FileFileVersionLen = 1
    public let FileChunksizeLen = 4
    public let FileDataSizeLen = 8
    public let FileVideoDurationlen = 4
    public let FileHeaderSizeLen = 4
    public let FileFileIdLen = 32
    public let FileHeaderBeginningLen:Int

    public let KeyFileTypeBundleEncrypted = 0
    public let KeyFileTypeBundlePlain = 1
    public let KeyFileTypePublicPlain = 2

    public let KeyFileBegginingLen:Int
    public let KeyFileVerLen = 1
    public let KeyFileTypeLen = 1
    public let KeyFileHeaderLen = 0

    public let KdfDifficultyNormal = 1
    public let KdfDifficultyHard = 2
    public let KdfDifficultyUltra = 3

    public let PWHASH_LEN = 64

    public let bufSize = 1024 * 1024

    private let hexArray:[Character] = [Character]("0123456789ABCDEF")

    init() {
        so = Sodium()
        FileBegginingLen = FileBeggining.count
        KeyFileBegginingLen = KeyFileBeggining.count
        FileHeaderBeginningLen = FileBegginingLen + FileFileVersionLen + FileFileIdLen + FileHeaderSizeLen

    }
    
    public func generateMainKeypair(password:String ) throws {
        try generateMainKeypair(password:password, privateKey:nil, publicKey:nil);
    }

    public func generateMainKeypair(password:String , privateKey:Bytes?, publicKey:Bytes?) throws{
        
        let pwdSalt:Bytes = so.randomBytes.buf(length: so.pwHash.SaltBytes) ?? []
        var result = savePrivateFile(filename: PwdSaltFilename, data: pwdSalt)
        
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
        
        guard let pwdKey = try getKeyFromPassword(password: password, difficulty: KdfDifficultyNormal) else {
            //TODO: throw exception
            return
        }
        guard let pwdEncNonce = so.randomBytes.buf(length: so.secretBox.NonceBytes) else {
            //TODO: throw exception
            return
        }
        result = savePrivateFile(filename: SKNONCEFilename, data: pwdEncNonce)
        if !result {
            //TODO: throw exception
            return
        }
        
        guard let encryptedPrivateKey = encryptSymmetric(key: pwdKey, nonce: pwdEncNonce, data: newPrivateKey!) else {
            //TODO: throw exception
            return
        }
        result = savePrivateFile(filename: PrivateKeyFilename, data: encryptedPrivateKey)
        if !result {
            //TODO: throw exception
            return
        }
        result = savePrivateFile(filename: PublicKeyFilename, data: newPublicKey!)
        if !result {
            //TODO: throw exception
            return
        }
    }
    
    public func getPrivateKey(password:String) throws  -> Bytes? {
        guard let encKey = try getKeyFromPassword(password: password, difficulty: KdfDifficultyNormal) else {
            //TODO: throw exception
            return nil
        }
        
        guard let encPrivKey = readPrivateFile(filename: PrivateKeyFilename) else {
            //TODO throw exception
            return nil
        }
        
        guard let nonce = readPrivateFile(filename: SKNONCEFilename) else {
            //TODO throw exception
            return nil
        }
        return try decryptSymmetric(key: encKey, nonce:nonce, data: encPrivKey)
    }
    
    public func reencryptPrivateKey(oldPassword:String , newPassword:String ) throws {
        
    }
    
    public func getEncryptedPrivateKey() -> Bytes? {
        return nil
    }
    
    public func getPublicKey() -> Bytes? {
        return nil
    }
    
    public func getServerPublicKey() -> Bytes? {
        return nil
    }
    
    public func saveEncryptedPrivateKey(encryptedPrivateKey:Bytes?) {
        
    }
    
    public func getPrivateKeyForExport(password:String) throws -> Bytes? {
        return nil
    }
    
    public func getPrivateKeyFromExportedKey(password:String , encPrivKey:Bytes?) throws -> Bytes? {
        return nil
    }
    
    public func exportKeyBundle(password:String) throws -> Bytes? {
        return nil
    }
    
    public func exportPublicKey() throws  -> Bytes? {
        return nil
    }
    
    public static func  getPublicKeyFromExport(exportedPublicKey:Bytes?) throws -> Bytes? {
        return nil
    }
    
    public func importKeyBundle(keys:Bytes?, password:String) throws {
        
    }
    
    public func importServerPublicKey(publicKey:Bytes?) throws  {
        
    }
    
    public func decryptSeal(enc:Bytes?, publicKey:Bytes?, privateKey:Bytes?) throws  -> Bytes? {
        return nil
    }
    
    public func encryptCryptoBox(message:Bytes, publicKey:Bytes?, privateKey:Bytes?) throws -> Bytes?  {
        return nil
    }
    
    public func getPublicKeyFromPrivateKey(privateKey:Bytes?) -> Bytes? {
        return nil
    }
    
    public func deleteKeys(){
    }
    
    public func getKeyFromPassword(password:String, difficulty:Int) throws -> Bytes? {
        
        guard let salt = readPrivateFile(filename: PwdSaltFilename), salt.count != so.pwHash.SaltBytes else {
            //TODO: throw exception
            return nil
        }

        var opsLimit = so.pwHash.OpsLimitInteractive
        var memlimit = so.pwHash.MemLimitInteractive
        
        switch difficulty {
        case KdfDifficultyHard:
            opsLimit = so.pwHash.OpsLimitModerate
            memlimit = so.pwHash.MemLimitModerate
            break
        case KdfDifficultyUltra:
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
    
    public func  getPasswordHashForStorage(password:String) -> [String : String] {
        return [ : ]
    }
    
    public func getPasswordHashForStorage(password:String, salt:String) -> String {
            return ""
    }
    
    public func getPasswordHashForStorage(password:String, salt:Bytes?) -> String {
        return ""
    }
    
    public func verifyStoredPassword(storedPassword:String, providedPassword:String) -> Bool {
        return false
    }
    
    private func encryptSymmetric(key:Bytes?, nonce:Bytes?, data:Bytes?) -> Bytes? {

        
        guard let key = key, key.count !=  so.secretBox.KeyBytes else {
            //TODO: throw exception
            return nil
        }
        
        guard let nonce = nonce, nonce.count != so.secretBox.NonceBytes else {
            //TODO: throw exception
            return nil
        }
        
        guard let message = data, message.count > 0 else {
            //TODO: throw exception
            return nil
        }
        return nil
    }
    
    private func decryptSymmetric(key:Bytes?, nonce:Bytes?, data:Bytes?) throws -> Bytes? {
        return nil
    }
    
    private func getNewHeader(symmetricKey:Bytes?, dataSize:UInt, filename:String, fileType:Int, fileId:Bytes?, videoDuration:Int) throws  -> Header {
        return Header()
    }
    private func writeHeader(output:OutputStream, header:Header, publicKey:Bytes?) throws  {
        
    }
    
    public func getFileHeader(bytes:Bytes?) throws -> Header {
        return Header()
    }
    
    public func getFileHeader(input:InputStream) throws {
        
    }
    
    public func getFilename(input:InputStream) -> String {
        return ""
    }
    
    public func encryptFile(output:OutputStream, data:Bytes?, filename:String, fileType:Int, videoDuration:Int) throws -> Bytes? {
        return nil
    }
    
    public func encryptFile(out:OutputStream , data:Bytes? , filename:String, fileType:Int, fileId:Bytes?, videoDuration:Int) throws -> Bytes? {
        return nil
    }
    
    public func encryptFile(input:InputStream, output:OutputStream, filename:String, fileType:Int, dataLength:UInt, videoDuration:Int) throws -> Bytes? {
        return nil
    }
    
    public func encryptFile(input:InputStream, output:OutputStream, filename:String, fileType:Int, dataLength:UInt, fileId:Bytes?, videoDuration:Int) throws -> Bytes? {
        return nil
    }
    
//    public func Bytes encryptFile(InputStream in, OutputStream out, String filename, int fileType, long dataLength, Bytes fileId, int videoDuration, CryptoProgress progress, AsyncTask<?,?,?> task) throws  { }
    
    public func getNewFileId() -> Bytes? {
        return nil
    }
    
    public func decryptFile(bytes:Bytes?) throws -> Bytes? {
        return nil
    }
    
//    public func Bytes decryptFile(Bytes bytes, AsyncTask<?,?,?> task) throws  { }
//    public func Bytes decryptFile(InputStream in) throws { }
//    public func Bytes decryptFile(InputStream in, CryptoProgress progress, AsyncTask<?,?,?> task) throws  {}
//    public func void decryptFile(InputStream in, OutputStream out, CryptoProgress progress, AsyncTask<?,?,?> task) throws { }
//    public func Bytes getRandomData(int length){ }
//    private boolean encryptData(InputStream in, OutputStream out, Header header) throws  { }
//    private boolean encryptData(InputStream in, OutputStream out, Header header, CryptoProgress progress, AsyncTask<?,?,?> task) throws  {}
//    private boolean decryptData(InputStream in, OutputStream out, Header header) throws  { }
//    private boolean decryptData(InputStream in, OutputStream out, Header header, CryptoProgress progress, AsyncTask<?,?,?> task) throws  {}

    private func savePrivateFile(filename:String, data:Bytes?) -> Bool {
        guard let out = OutputStream(toFileAtPath: filename, append: false) else {
            // TODO: throw exception
            return false
        }
        
        guard let data = data else {
            // TODO: throw exception
            return false
        }
        
        return data.count == out.write(data, maxLength: data.count)
    }
    
    private func readPrivateFile(filename:String ) -> Bytes? {
        guard let input:InputStream = InputStream(fileAtPath: filename) else {
            // TODO: throw exception
            return nil
        }
        
        let outBuffer:OutputStream = OutputStream(toMemory: ())
        var buffer = Bytes(repeating: 0, count: bufSize)
        while input.read(&buffer, maxLength: buffer.count) > 0 {
            outBuffer.write(&buffer, maxLength: buffer.count)
        }
        return outBuffer.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? Bytes
    }
    
//    private boolean deletePrivateFile(String filename){ }
//    public static Bytes sha256(Bytes data){ }
//    public static String byte2hex(Bytes bytes){ }
//    public static Bytes hex2byte(String s){ }
//    public static Bytes intToByteArray(int a){ }
//    public static int byteArrayToInt(Bytes b) { }
//    public static Bytes longToByteArray(long x) { }
//    public static long byteArrayToLong(Bytes bytes) { }
//    public static String byteArrayToBase64(Bytes bytes) { }
//    public static Bytes base64ToByteArray(String base64str) { }
//    public static String byteArrayToBase64Default(Bytes bytes) { }
//    public static Bytes base64ToByteArrayDefault(String base64str) { }
//    public static String getFileHeaders(String encFilePath, String encThumbPath) throws  {}
//    public static Bytes getFileHeaderAsIs(String filePath) throws  {}
//    public static int getOverallHeaderSize(InputStream in) throws  {}
    
    public struct Header{
    }
}
