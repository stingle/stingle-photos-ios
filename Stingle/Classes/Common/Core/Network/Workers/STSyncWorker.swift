//
//  STSyncWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/5/21.
//

import Foundation

class STSyncWorker: STWorker {
        
    func getUpdates() {
        let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
        let request = STSyncRequest.getUpdates(lastSeenTime: dbInfo.lastSeenTimeSeccounds,
                                               lastTrashSeenTime: dbInfo.lastTrashSeenTimeSeccounds,
                                               lastAlbumsSeenTime: dbInfo.lastAlbumsSeenTimeSeccounds,
                                               lastAlbumFilesSeenTime: dbInfo.lastAlbumFilesSeenTimeSeccounds,
                                               lastDelSeenTime: dbInfo.lastDelSeenTimeSeccounds,
                                               lastContactsSeenTime: dbInfo.lastContactsSeenTimeSeccounds)
        
        

        self.request(request: request) { (response: STSync) in
            
            STApplication.shared.dataBase.sync(response, finish: { error in
                
                var files = STApplication.shared.dataBase.galleryProvider.getAllObjects()
                var albums = STApplication.shared.dataBase.albumsProvider.getAllObjects()
                var albumFiles = STApplication.shared.dataBase.albumFilesProvider.getAllObjects()
                var trashFiles = STApplication.shared.dataBase.trashProvider.getAllObjects()
                var contacts = STApplication.shared.dataBase.contactProvider.getAllObjects()
                
                print("")
                
            })

            

        } failure: { (error) in


            print(error.message)

        }
        
    }

    
}
