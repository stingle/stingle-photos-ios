//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

extension STDataBase {
    
    class ContactProvider: SyncProvider<STContact, STLibrary.DeleteFile.Contact> {
        
        override var providerType: SyncProviderType {
            return .contact
        }
    
    }
    
}
