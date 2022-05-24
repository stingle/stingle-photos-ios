//
//  STTrashProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class TrashProvider: SyncProvider<STLibrary.TrashFile, STLibrary.DeleteFile.Trash> {
        
        override var providerType: SyncProviderType {
            return .trash
        }
        
    }
    
}
