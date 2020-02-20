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
        FileBegginingLen = FileBeggining.count
        KeyFileBegginingLen = KeyFileBeggining.count
        FileHeaderBeginningLen = FileBegginingLen + FileFileVersionLen + FileFileIdLen + FileHeaderSizeLen

    }
    
    public func generateMainKeypair(password:String ) throws {
        try generateMainKeypair(password:password, privateKey:nil, publicKey:nil);
    }

    public func generateMainKeypair(password:String , privateKey:[UInt8]?, publicKey:[UInt8]?) throws{
        
    }
    
    public func getPrivateKey(password:String) throws  -> [UInt8] {
        return []
    }
    
    public func reencryptPrivateKey(oldPassword:String , newPassword:String ) throws {
        
    }
    
    public func getEncryptedPrivateKey() -> [UInt8] {
        return []
    }
    
    public func getPublicKey() -> [UInt8] {
        return []
    }
    
    public func getServerPublicKey() -> [UInt8] {
        return []
    }
    
    public func saveEncryptedPrivateKey(encryptedPrivateKey:[UInt8]) {
        
    }
    
    public func getPrivateKeyForExport(password:String) throws -> [UInt8] {
        return []
    }
    
    public func getPrivateKeyFromExportedKey(password:String , encPrivKey:[UInt8]) throws -> [UInt8] {
        return []
    }
    
    public func exportKeyBundle(password:String) throws -> [UInt8] {
        return []
    }
    
    public func exportPublicKey() throws  -> [UInt8] {
        return []
    }
    
    public static func  getPublicKeyFromExport(exportedPublicKey:[UInt8]) throws -> [UInt8] {
        return []
    }
    
    public func importKeyBundle(keys:[UInt8], password:String) throws {
        
    }
    
    public func importServerPublicKey(publicKey:[UInt8]) throws  {
        
    }
    
    public func decryptSeal(enc:[UInt8], publicKey:[UInt8], privateKey:[UInt8]) throws  -> [UInt8] {
        return []
    }
    
    public func encryptCryptoBox(message:[UInt8], publicKey:[UInt8], privateKey:[UInt8]) throws -> [UInt8]  {
        return []
    }
    
    public func getPublicKeyFromPrivateKey(privateKey:[UInt8]) -> [UInt8] {
        return []
    }
    
    public func deleteKeys(){
    }
    
    public func getKeyFromPassword(String password:String, difficulty:Int) throws -> [UInt8] {
        return []
    }
    
    public func  getPasswordHashForStorage(password:String) -> [String : String] {
        return [ : ]
    }
    
    public func getPasswordHashForStorage(password:String, salt:String) -> String {
            return ""
    }
    
    public func getPasswordHashForStorage(password:String, salt:[UInt8]) -> String {
        return ""
    }
    
    public func verifyStoredPassword(storedPassword:String, providedPassword:String) -> Bool {
        return false
    }
    
    //protected func encryptSymmetric([UInt8] key, [UInt8] nonce, [UInt8] data) -> [UInt8] { }
    //protected func decryptSymmetric([UInt8] key, [UInt8] nonce, [UInt8] data) throws -> [UInt8] { }
    //protected func getNewHeader([UInt8] symmetricKey, long dataSize, String filename, int fileType, [UInt8] fileId, int videoDuration) throws  -> Header { }
    //protected func writeHeader(OutputStream out, Header header, [UInt8] publicKey) throws  {}
    
    public func getFileHeader(bytes:[UInt8]) throws -> Header {
        return Header()
    }
    
    public func getFileHeader(input:InputStream) throws {
        
    }
    
    public func getFilename(input:InputStream) -> String {
        return ""
    }
    
    public func encryptFile(output:OutputStream, data:[UInt8], filename:String, fileType:Int, videoDuration:Int) throws -> [UInt8] {
        return []
    }
    
    public func encryptFile(out:OutputStream , data:[UInt8] , filename:String, fileType:Int, fileId:[UInt8], videoDuration:Int) throws -> [UInt8] {
        return []
    }
    
    public func encryptFile(input:InputStream, output:OutputStream, filename:String, fileType:Int, dataLength:UInt, videoDuration:Int) throws -> [UInt8] {
        return []
    }
    
    public func encryptFile(input:InputStream, output:OutputStream, filename:String, fileType:Int, dataLength:UInt, fileId:[UInt8], videoDuration:Int) throws -> [UInt8]   {
        return []
    }
    
//    public func [UInt8] encryptFile(InputStream in, OutputStream out, String filename, int fileType, long dataLength, [UInt8] fileId, int videoDuration, CryptoProgress progress, AsyncTask<?,?,?> task) throws  { }
    
    public func getNewFileId() -> [UInt8] {
        return []
    }
    
    public func decryptFile(bytes:[UInt8]) throws -> [UInt8] {
        return []
    }
    
//    public func [UInt8] decryptFile([UInt8] bytes, AsyncTask<?,?,?> task) throws  { }
//    public func [UInt8] decryptFile(InputStream in) throws { }
//    public func [UInt8] decryptFile(InputStream in, CryptoProgress progress, AsyncTask<?,?,?> task) throws  {}
//    public func void decryptFile(InputStream in, OutputStream out, CryptoProgress progress, AsyncTask<?,?,?> task) throws { }
//    public func [UInt8] getRandomData(int length){ }
//    protected boolean encryptData(InputStream in, OutputStream out, Header header) throws  { }
//    protected boolean encryptData(InputStream in, OutputStream out, Header header, CryptoProgress progress, AsyncTask<?,?,?> task) throws  {}
//    protected boolean decryptData(InputStream in, OutputStream out, Header header) throws  { }
//    protected boolean decryptData(InputStream in, OutputStream out, Header header, CryptoProgress progress, AsyncTask<?,?,?> task) throws  {}
//    protected boolean savePrivateFile(String filename, [UInt8] data){ }
//    protected [UInt8] readPrivateFile(String filename){ }
//    protected boolean deletePrivateFile(String filename){ }
//    public static [UInt8] sha256([UInt8] data){ }
//    public static String byte2hex([UInt8] bytes){ }
//    public static [UInt8] hex2byte(String s){ }
//    public static [UInt8] intToByteArray(int a){ }
//    public static int byteArrayToInt([UInt8] b) { }
//    public static [UInt8] longToByteArray(long x) { }
//    public static long byteArrayToLong([UInt8] bytes) { }
//    public static String byteArrayToBase64([UInt8] bytes) { }
//    public static [UInt8] base64ToByteArray(String base64str) { }
//    public static String byteArrayToBase64Default([UInt8] bytes) { }
//    public static [UInt8] base64ToByteArrayDefault(String base64str) { }
//    public static String getFileHeaders(String encFilePath, String encThumbPath) throws  {}
//    public static [UInt8] getFileHeaderAsIs(String filePath) throws  {}
//    public static int getOverallHeaderSize(InputStream in) throws  {}
    
    public struct Header{
    }
}
