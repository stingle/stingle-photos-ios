//
//  STApplication.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

class STApplication {
    
    static let shared = STApplication()
    
    let dataBase = STDataBase()
    let crypto = Crypto()
    
    private init() {}
    
}

extension STApplication {
    
    func isLogedIn() -> Bool {
        do {
            return try  STValidator().validate(user: self.dataBase.userProvider.user)
        } catch  {
            return false
        }
    }
    
    func user() -> STUser? {
        if self.isLogedIn() {
            return self.dataBase.userProvider.user
        }
        return nil
    }
    
}
