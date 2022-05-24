//
//  STAlbumsProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

extension STDataBase {
    
    class AlbumsProvider: SyncProvider<STLibrary.Album, STLibrary.DeleteFile.Album> {
        
        override var providerType: SyncProviderType {
            return .albums
        }

                
    }

}
