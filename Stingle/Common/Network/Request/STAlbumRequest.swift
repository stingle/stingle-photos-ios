//
//  STCreateAlbumRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/28/21.
//

import Foundation

enum STAlbumRequest {
    
    case create(album: STLibrary.Album)
    case moveFile(fromSet: STLibrary.DBSet, toSet: STLibrary.DBSet, albumIdFrom: String?, albumIdTo: String?, isMoving: Bool, headers: [String: String], files: [ILibraryFile])
    case deleteAlbum(albumID: String)
    case sharedAlbum(album: STLibrary.Album, sharingKeys: [String: String])
    case setCover(album: STLibrary.Album, caver: String?)
    case rename(album: STLibrary.Album, metadata: String)
    case leaveAlbum(album: STLibrary.Album)
    case unshareAlbum(album: STLibrary.Album)
    case editPermsAlbum(album: STLibrary.Album)

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
        case .sharedAlbum(let album, let sharingKeys):
            let albumData = album.toString() ?? ""
            let sharingKeys = sharingKeys.toString() ?? ""
            return ["album": albumData, "sharingKeys": sharingKeys]
        case .setCover(let album, let caver):
            if let caver = caver {
                return ["albumId": album.albumId, "cover": caver]
            }
            return ["albumId": album.albumId]
        case .rename(let album, let metadata):
            return ["albumId": album.albumId, "metadata": metadata]
        case .leaveAlbum(let album):
            return ["albumId": album.albumId]
        case .unshareAlbum(let album):
            return ["albumId": album.albumId]
        case .editPermsAlbum(let album):
            let albumData = album.toString() ?? ""
            return ["album": albumData]
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
        case .sharedAlbum:
            return "sync/share"
        case .setCover:
            return "sync/changeAlbumCover"
        case .rename:
            return "sync/renameAlbum"
        case .leaveAlbum:
            return "sync/leaveAlbum"
        case .unshareAlbum:
            return "sync/unshareAlbum"
        case .editPermsAlbum:
            return "sync/editPerms"
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
        case .sharedAlbum:
            return .post
        case .setCover:
            return .post
        case .rename:
            return .post
        case .leaveAlbum:
            return .post
        case .unshareAlbum:
            return .post
        case .editPermsAlbum:
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
        case .sharedAlbum:
            return nil
        case .setCover:
            return nil
        case .rename:
            return nil
        case .leaveAlbum:
            return nil
        case .unshareAlbum:
            return nil
        case .editPermsAlbum:
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
        case .sharedAlbum:
            return STNetworkDispatcher.Encoding.body
        case .setCover:
            return STNetworkDispatcher.Encoding.body
        case .rename:
            return STNetworkDispatcher.Encoding.body
        case .leaveAlbum:
            return STNetworkDispatcher.Encoding.body
        case .unshareAlbum:
            return STNetworkDispatcher.Encoding.body
        case .editPermsAlbum:
            return STNetworkDispatcher.Encoding.body
        }
    }

}
