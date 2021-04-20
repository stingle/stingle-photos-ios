//
//  STUser.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

class STUser: ICDConvertable {
    
    let email: String
    let homeFolder: String
    let isKeyBackedUp: Bool
    let token: String
    let userId: String
    
    var identifier: String {
        return self.userId
    }
    
    init(email: String, homeFolder: String, isKeyBackedUp: Bool, token: String, userId: String) {
        self.email = email
        self.homeFolder = homeFolder
        self.isKeyBackedUp = isKeyBackedUp
        self.token = token
        self.userId = userId
    }
    
    required init(model: STCDUser) throws {
        
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
    }


}
