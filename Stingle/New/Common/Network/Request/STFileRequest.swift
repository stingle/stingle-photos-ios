//
//  STFileRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/9/21.
//

import Foundation

enum STFileRequest {
    case getFileDownloadUrl(filename: String, dbSet: STLibrary.DBSet)
}

extension STFileRequest: STRequest {
    
    var path: String {
        switch self {
        case .getFileDownloadUrl:
            return "sync/getUrl"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .getFileDownloadUrl:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .getFileDownloadUrl:
            return nil
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case .getFileDownloadUrl(let filename, let dbSet):
            return ["file": filename, "set": dbSet.rawValue, "token": self.token ?? ""]
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .getFileDownloadUrl:
            return STNetworkDispatcher.Encoding.body
        }
    }
    
}

enum STFileStreamRequest: IStreamRequest {
    
    case downloadRange(url: URL, offset: UInt64, length: UInt64)
    
    var url: String {
        switch self {
        case .downloadRange(let url, _, _):
            return url.absoluteString
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .downloadRange:
            return .get
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .downloadRange(_, let offset, let length):
            return ["Range": "bytes=\(offset)-\(offset + length)"]
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case .downloadRange:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .downloadRange:
            return STNetworkDispatcher.Encoding.body
        }
    }

//      return nil//["Range": "bytes=\(200)-\(7000)"]

}
