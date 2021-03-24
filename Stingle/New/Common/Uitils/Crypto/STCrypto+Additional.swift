//
//  STCrypto+Additional.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/20/21.
//

import UIKit

extension STCrypto {
    
    func decryptData(data: Data, header: STHeader?) throws -> Data {
        let output = OutputStream(toMemory: ())
        let input = InputStream(data: data)
        
        defer {
            input.close()
            output.close()
        }
        
        input.open()
        var result: Data?
                
        try self.decryptFile(input: input, output: output, header: header) { (bytes) in
            result = Data(bytes ?? [])
        }
        
        
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
        
        let result = try self.decryptData(data: Data(bytes), header: header)
        input.close()
        output.close()
        return result
    }
    

    func fileModificationDate(url: URL) -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
}
