//
//  STSyncWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/5/21.
//

import Foundation

class STSyncWorker: STWorker {
    
    func getUpdates() {
        
        let request = STSyncRequest.getUpdates(lastSeenTime: 0, lastTrashSeenTime: 0, lastAlbumsSeenTime: 0, lastAlbumFilesSeenTime: 0, lastDelSeenTime: 0, lastContactsSeenTime: 0)
        
        self.request(request: request) { (response: STSync?) in
            
            print("")
            
        } failure: { (error) in
            

            print(error.message)
            
        }


        
    }

    
}
