//
//  STSyncWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/5/21.
//

import Foundation

class STSyncWorker: STWorker {
        
    func getUpdates(success: Success<STSync>? = nil, failure: Failure? = nil) {
        
        let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
        let request = STSyncRequest.getUpdates(lastSeenTime: dbInfo.lastSeenTimeSeccounds,
                                               lastTrashSeenTime: dbInfo.lastTrashSeenTimeSeccounds,
                                               lastAlbumsSeenTime: dbInfo.lastAlbumsSeenTimeSeccounds,
                                               lastAlbumFilesSeenTime: dbInfo.lastAlbumFilesSeenTimeSeccounds,
                                               lastDelSeenTime: dbInfo.lastDelSeenTimeSeccounds,
                                               lastContactsSeenTime: dbInfo.lastContactsSeenTimeSeccounds)
        
        self.request(request: request) { (response: STSync) in
            success?(response)
        } failure: { (error) in
            failure?(error)
        }
        
    }

    
}
