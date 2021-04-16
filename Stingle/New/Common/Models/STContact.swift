//
//  STContact.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import Foundation

class STContact: Codable, ICDConvertable {
    
    private enum CodingKeys: String, CodingKey {
        case email = "email"
        case publicKey = "publicKey"
        case userId = "userId"
        case dateUsed = "dateUsed"
        case dateModified = "dateModified"
    }
    
    var email: String
    var publicKey: String?
    var userId: String
    var dateUsed: Date
    var dateModified: Date
    
   
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.publicKey = try container.decodeIfPresent(String.self, forKey: .publicKey)
        self.userId = try container.decode(String.self, forKey: .userId)
        
        let dateUsedStr = try container.decode(String.self, forKey: .dateUsed)
        let dateModifiedStr = try container.decode(String.self, forKey: .dateModified)
        
        guard let dateUsed = UInt64(dateUsedStr), let dateModified = UInt64(dateModifiedStr) else {
            throw STLibrary.LibraryError.parsError
        }
        self.dateUsed = Date(milliseconds: dateUsed)
        self.dateModified = Date(milliseconds: dateModified)
        
    }
    
    required init(model: STCDContact) throws {
        
        guard let email = model.email,
              let userId = model.userId,
              let dateUsed = model.dateUsed,
              let dateModified = model.dateModified else {
            throw STLibrary.LibraryError.parsError
        }
        
        self.email = email
        self.publicKey = model.publicKey
        self.userId = userId
        self.dateUsed = dateUsed
        self.dateModified = dateModified
    }
    
    func toManagedModelJson() throws -> [String : Any] {
        var json = [String : Any]()
        json.addIfNeeded(key: "email", value: self.email)
        json.addIfNeeded(key: "publicKey", value: self.publicKey)
        json.addIfNeeded(key: "userId", value: self.userId)
        json.addIfNeeded(key: "dateUsed", value: self.dateUsed)
        json.addIfNeeded(key: "dateModified", value: self.dateModified)
        return json
    }
    
}
