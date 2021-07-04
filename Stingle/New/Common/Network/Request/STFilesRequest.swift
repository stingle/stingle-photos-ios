//
//  STFilesRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/3/21.
//

import Foundation

enum STFilesRequest {
    case moveToTrash(files: [STLibrary.File])
}

extension STFilesRequest: IEncryptedRequest {
    
    var bodyParams: [String : Any]? {
        switch self {
        case .moveToTrash(let files):
            var params = [String: Any]()
            params["setFrom"] = "\(STLibrary.DBSet.file.rawValue)"
            params["setTo"] = "\(STLibrary.DBSet.trash.rawValue)"
            params["isMoving"] = "1"
            params["count"] = "\(files.count)"
            for (index, file) in files.enumerated() {
                guard file.isRemote else {
                    continue
                }
                params["filename" + "\(index)"] = file.file
            }
            return params
        }
    }
    
    var path: String {
        switch self {
        case .moveToTrash:
            return "sync/moveFile"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .moveToTrash:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .moveToTrash:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .moveToTrash:
            return STNetworkDispatcher.Encoding.body
        }
    }
        
}
