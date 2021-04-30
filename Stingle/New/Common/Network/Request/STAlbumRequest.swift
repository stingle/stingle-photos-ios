//
//  STCreateAlbumRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/28/21.
//

import Foundation

enum STAlbumRequest {
    case create(album: STLibrary.Album)
    case moveFile(fromSet: STLibrary.DBSet, toSet: STLibrary.DBSet, albumIdFrom: String, albumIdTo: String?, isMoving: Bool, headers: [String: String], files: [STLibrary.File])
    case deleteAlbum(albumID: String)
}

extension STAlbumRequest: IEncryptedRequest {
    
    var bodyParams: [String : Any]? {
        switch self {
        case .create(let album):
            return ["albumId": album.albumId,
                    "encPrivateKey": album.encPrivateKey,
                    "publicKey": album.publicKey,
                    "metadata": album.metadata,
                    "dateCreated": album.dateCreated.millisecondsSince1970,
                    "dateModified": album.dateModified.millisecondsSince1970]
            
        case .moveFile(let fromSet, let toSet, let albumIdFrom, let albumIdTo, let isMoving, let headers, let files):
            var params = [String: Any]()
            params["setFrom"] = "\(fromSet.rawValue)"
            params["setTo"] = "\(toSet.rawValue)"
            params["albumIdFrom"] = albumIdFrom
            params["albumIdTo"] = albumIdTo
            params["isMoving"] = isMoving ? "1" : "0"
            params["count"] = "\(files.count)"
            
            for (index, file) in files.enumerated() {
                guard file.isRemote else {
                    continue
                }
                params["filename" + "\(index)"] = file.file
                if let header = headers[file.file] {
                    params["headers" + "\(index)"] = header
                }
            }
            return params
        case .deleteAlbum(let albumID):
            return ["albumId": albumID]
        }
    }
    
    var path: String {
        switch self {
        case .create:
            return "sync/addAlbum"
        case .moveFile:
            return "sync/moveFile"
        case .deleteAlbum:
            return "sync/deleteAlbum"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .create:
            return .post
        case .moveFile:
            return .post
        case .deleteAlbum:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .create:
            return nil
        case .moveFile:
            return nil
        case .deleteAlbum:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .create:
            return STNetworkDispatcher.Encoding.body
        case .moveFile:
            return STNetworkDispatcher.Encoding.body
        case .deleteAlbum:
            return STNetworkDispatcher.Encoding.body
        }
    }

}
