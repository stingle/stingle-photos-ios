//
//  STLibraryFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/6/21.
//

import Foundation

extension STLibrary {
        
    class File: Codable {
        
        private enum CodingKeys: String, CodingKey {
            case name = "file"
            case version = "version"
            case headers = "headers"
            case dateCreated = "dateCreated"
            case dateModified = "dateModified"
        }
        
        var name: String
        var version: String
        var headers: String
        var dateCreated: Date
        var dateModified: Date
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
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
    }
    
}
