//
//  STUser.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData

public class STUser: ICDConvertable {
        
    public let email: String
    public let homeFolder: String
    public let isKeyBackedUp: Bool
    public let token: String
    public let userId: String
    public var managedObjectID: NSManagedObjectID?
    
    public var identifier: String {
        return self.userId
    }
    
    private enum CodingKeys: String, CodingKey {
        case email = "email"
        case homeFolder = "homeFolder"
        case isKeyBackedUp = "isKeyBackedUp"
        case token = "token"
        case userId = "userId"
    }
    
    init(email: String, homeFolder: String, isKeyBackedUp: Bool, token: String, userId: String, managedObjectID: NSManagedObjectID?) {
        self.email = email
        self.homeFolder = homeFolder
        self.isKeyBackedUp = isKeyBackedUp
        self.token = token
        self.userId = userId
        self.managedObjectID = managedObjectID
    }
    
    required public init(model: STCDUser) throws {
        
        guard let email = model.email,
              let homeFolder = model.homeFolder,
              let token = model.token,
              let userId = model.userId
        else {
            throw STLibrary.LibraryError.parsError
        }
        
        self.email = email
        self.homeFolder = homeFolder
        self.isKeyBackedUp = model.isKeyBackedUp
        self.token = token
        self.userId = userId
        self.managedObjectID = model.objectID
    }
    
    public func update(model: STCDUser) {
        model.email = self.email
        model.homeFolder = self.homeFolder
        model.isKeyBackedUp = self.isKeyBackedUp
        model.token = self.token
        model.userId = self.userId
        model.identifier =  self.userId
    }

}
