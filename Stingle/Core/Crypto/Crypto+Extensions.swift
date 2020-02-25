//
//  Crypto+Extensions.swift
//  Stingle
//
//  Created by Davit Grigoryan on 22.02.2020.
//  Copyright © 2020 Davit Grigoryan. All rights reserved.
//

//This extension is for add functions which are not ported from Clibsodium
import Sodium
import Clibsodium

extension SecretBox {
    
    func seal(message: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
        guard secretKey.count == KeyBytes else { return nil }
        var authenticatedCipherText = Bytes(repeating: 0, count: message.count + MacBytes)

        crypto_secretbox_easy (
            &authenticatedCipherText,
            message, UInt64(message.count),
            nonce,
            secretKey
        )
        return authenticatedCipherText
    }
    
    func exportPublicKey(secretKey:Bytes) -> Bytes? {
        guard secretKey.count == KeyBytes else { return nil }
        var publicKey = Bytes(repeating: 0, count: crypto_box_publickeybytes())
        crypto_scalarmult_base(&publicKey, secretKey)
        return publicKey
    }    
}
