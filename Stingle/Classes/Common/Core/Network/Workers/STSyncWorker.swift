//
//  STSyncWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/5/21.
//

import Foundation

class STSyncWorker: STWorker {
    
    
    
    func getUpdates() {
        
        
        var files = STApplication.shared.dataBase.galleryProvider.getAllObjects()
        var albums = STApplication.shared.dataBase.albumsProvider.getAllObjects()
        
        STApplication.shared.dataBase.galleryProvider.deleteAll()
        STApplication.shared.dataBase.albumFilesProvider.deleteAll()
        STApplication.shared.dataBase.trashProvider.deleteAll()
        STApplication.shared.dataBase.albumFilesProvider.deleteAll()
        STApplication.shared.dataBase.contactProvider.deleteAll()
        
        var trashFiles = STApplication.shared.dataBase.trashProvider.getAllObjects()
        
        print("")
        
        let request = STSyncRequest.getUpdates(lastSeenTime: 0, lastTrashSeenTime: 0, lastAlbumsSeenTime: 0, lastAlbumFilesSeenTime: 0, lastDelSeenTime: 0, lastContactsSeenTime: 0)

        self.request(request: request) { (response: STSync) in
            STApplication.shared.dataBase.sync(response)
            
            var files = STApplication.shared.dataBase.galleryProvider.getAllObjects()
            var albums = STApplication.shared.dataBase.albumsProvider.getAllObjects()
            var albumFiles = STApplication.shared.dataBase.albumFilesProvider.getAllObjects()
            var trashFiles = STApplication.shared.dataBase.trashProvider.getAllObjects()
            var contacts = STApplication.shared.dataBase.contactProvider.getAllObjects()
            
            print("")
        } failure: { (error) in


            print(error.message)

        }
        
    }

    
}
