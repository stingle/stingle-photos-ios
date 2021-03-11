//
//  STLibraryFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import Foundation

extension STLibrary {
        
    class File: Codable, ICDConvertable {
                
        private enum CodingKeys: String, CodingKey {
            case file = "file"
            case version = "version"
            case headers = "headers"
            case dateCreated = "dateCreated"
            case dateModified = "dateModified"
        }
        
        let file: String
        let version: String
        let headers: String
        let dateCreated: Date
        let dateModified: Date
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.file = try container.decode(String.self, forKey: .file)
            self.version = try container.decode(String.self, forKey: .version)
            self.headers = try container.decode(String.self, forKey: .headers)
            let dateCreatedStr = try container.decode(String.self, forKey: .dateCreated)
            let dateModifiedStr = try container.decode(String.self, forKey: .dateModified)
            guard let dateCreated = UInt64(dateCreatedStr), let dateModified = UInt64(dateModifiedStr) else {
                throw LibraryError.parsError
            }
            self.dateCreated = Date(milliseconds: dateCreated)
            self.dateModified = Date(milliseconds: dateModified)
        }
        
        required init(model: STCDFile) throws {
            guard let file = model.file,
                  let version = model.version,
                  let headers = model.headers,
                  let dateCreated = model.dateCreated,
                  let dateModified = model.dateModified
            else {
                throw LibraryError.parsError
            }
            
            self.file = file
            self.version = version
            self.headers = headers
            self.dateCreated = dateCreated
            self.dateModified = dateModified
        }
        
        func toManagedModelJson() throws -> [String : Any] {
            return ["file": self.file, "version": self.version, "headers": self.headers, "dateCreated": self.dateCreated, "dateModified": self.dateModified]
        }
        
    }
    
}
