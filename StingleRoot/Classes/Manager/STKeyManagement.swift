//
//  STKeyManagement.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/30/21.
//

import Foundation

public class STKeyManagement {
    
    static private let crypto = STApplication.shared.crypto
    
    private static var secret:[UInt8]?

    static public var key: [UInt8]? { get { return STKeyManagement.secret } set(newKey) { STKeyManagement.secret = newKey } }
    
    static public func importServerPublicKey(pbk: String) {
        guard let pbkData = self.crypto.base64ToByte(encodedStr: pbk) else {
            return
        }
        do {
            try self.crypto.importServerPublicKey(pbk: pbkData)
        } catch {
            STLogger.log(error: error)
        }
    }
    
    static public func importKeyBundle(keyBundle:String, password:String) -> Bool {
        guard let keyBundleBytes = self.crypto.base64ToByte(encodedStr: keyBundle) else {
            return false
        }
        do {
            try self.crypto.importKeyBundle(keys: keyBundleBytes, password: password)
        } catch {
            STLogger.log(error: error)
            return false
        }
        return true
    }
    
    static public func signOut() {
        STKeyManagement.key = nil
    }
    
    static public func getUploadKeyBundle(password: String?, includePrivateKey: Bool) throws -> String {
        var keyBundleBytes:[UInt8]? = nil
        do {
            if includePrivateKey {
                guard let password = password else {
                    throw KeyManagementError.password
                }
                keyBundleBytes = try self.crypto.exportKeyBundle(password: password)
            } else {
                keyBundleBytes = try self.crypto.exportPublicKey()
            }
        } catch {
            throw KeyManagementError.password
        }
        guard let keyBundle = self.crypto.bytesToBase64(data: keyBundleBytes!) else {
            throw KeyManagementError.unknown
        }
        return keyBundle
    }
}

public extension STKeyManagement {
    
    enum KeyManagementError: IError {
        case password
        case unknown
        
        public var message: String {
            switch self {
            case .password:
                return "error_password_not_valed".localized
            case .unknown:
                return "error_data_not_found".localized
            }
        }
        
    }
    
}
