//
//  STContact.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import CoreData

public class STContact: Codable, ICDSynchConvertable {
                
    private enum CodingKeys: String, CodingKey {
        case email = "email"
        case publicKey = "publicKey"
        case userId = "userId"
        case dateUsed = "dateUsed"
        case dateModified = "dateModified"
    }
    
    public var email: String
    public var publicKey: String?
    public var userId: String
    public var dateUsed: Date
    public var dateModified: Date
    public var managedObjectID: NSManagedObjectID?
    
    public var identifier: String {
        return self.userId
    }
   
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.publicKey = try container.decodeIfPresent(String.self, forKey: .publicKey)
        self.userId = try container.decode(String.self, forKey: .userId)
        
        let defaultDate = "\(0)"
        let dateUsedStr = try container.decodeIfPresent(String.self, forKey: .dateUsed) ?? defaultDate
        let dateModifiedStr = try container.decodeIfPresent(String.self, forKey: .dateModified) ?? defaultDate
        
        guard let dateUsed = UInt64(dateUsedStr), let dateModified = UInt64(dateModifiedStr) else {
            throw STLibrary.LibraryError.parsError
        }
        self.dateUsed = Date(milliseconds: dateUsed)
        self.dateModified = Date(milliseconds: dateModified)
        self.managedObjectID = nil
    }
    
    public required init(model: STCDContact) throws {
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
        self.managedObjectID = model.objectID
    }
    
    public func diffStatus(with rhs: STCDContact) -> STDataBase.ModelModifyStatus {
        guard self.identifier == rhs.identifier else { return .none }
        guard let dateModified = rhs.dateModified else { return .high(type: .upgrade) }
        if dateModified == rhs.dateModified {
            return .equal
        }
        if dateModified < self.dateModified {
            return .high(type: .upgrade)
        }
        return .low
    }
    
    public func update(model: STCDContact) {
        model.email = self.email
        model.publicKey = self.publicKey
        model.userId = self.userId
        model.dateUsed = self.dateUsed
        model.dateModified = self.dateModified
        model.identifier = self.identifier
    }
    
    public func updateLowMode(model: STCDContact) {}
    
    public func toManagedModelJson() throws -> [String : Any] {
        var json = [String : Any]()
        json.addIfNeeded(key: "email", value: self.email)
        json.addIfNeeded(key: "publicKey", value: self.publicKey)
        json.addIfNeeded(key: "userId", value: self.userId)
        json.addIfNeeded(key: "dateUsed", value: self.dateUsed)
        json.addIfNeeded(key: "dateModified", value: self.dateModified)
        json.addIfNeeded(key: "identifier", value: self.identifier)
        return json
    }
    
    public static func > (lhs: STContact, rhs: STContact) -> Bool {
        guard lhs.identifier == rhs.identifier else {
            return false
        }
        return lhs.dateModified > rhs.dateModified
    }
    
}
