//
//  STSyncRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/2/21.
//  Copyright © 2021 Stingle. All rights reserved.
//

import Foundation

enum STSyncRequest {
    
    case getUpdates(lastSeenTime: UInt64, lastTrashSeenTime: UInt64, lastAlbumsSeenTime: UInt64, lastAlbumFilesSeenTime: UInt64, lastDelSeenTime: UInt64, lastContactsSeenTime: UInt64)

}



extension STSyncRequest: STRequest {

	var path: String {
		switch self {
		case .getUpdates:
			return "sync/getUpdates"
		}
	}

	var method: STNetworkDispatcher.Method {
		switch self {
		case .getUpdates:
            return .post
		}
	}

	var headers: [String : String]? {
		switch self {
		case .getUpdates:
			return nil
		}
	}

	var parameters: [String : Any]? {
		switch self {
		case .getUpdates(let lastSeenTime, let lastTrashSeenTime, let lastAlbumsSeenTime, let lastAlbumFilesSeenTime, let lastDelSeenTime, let lastContactsSeenTime):
            let token = self.token ?? "" 
            return ["filesST": "\(lastSeenTime)", "trashST": "\(lastTrashSeenTime)", "albumsST": "\(lastAlbumsSeenTime)", "albumFilesST":  "\(lastAlbumFilesSeenTime)", "delST": "\(lastDelSeenTime)", "cntST": "\(lastContactsSeenTime)", "token": token]
		}
	}

	var encoding: STNetworkDispatcher.Encoding {
		switch self {
		case .getUpdates:
            return .body
		}
	}

}



