//
//  STFilesRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/3/21.
//

import Foundation

enum STFilesRequest {
    case moveToTrash(files: [STLibrary.GaleryFile])
    case delete(files: [STLibrary.TrashFile])
    case moveToGalery(files: [STLibrary.TrashFile])
}

extension STFilesRequest: IEncryptedRequest {
    
    var bodyParams: [String : Any]? {
        switch self {
        case .moveToTrash(let files):
            var params = [String: Any]()
            params["setFrom"] = "\(STLibrary.DBSet.galery.rawValue)"
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
        case .delete(let files):
            var params = [String: Any]()
            params["count"] = "\(files.count)"
            
            for (index, file) in files.enumerated() {
                guard file.isRemote else {
                    continue
                }
                params["filename" + "\(index)"] = file.file
            }
            return params
        case .moveToGalery(let files):
            var params = [String: Any]()
            params["setFrom"] = "\(STLibrary.DBSet.trash.rawValue)"
            params["setTo"] = "\(STLibrary.DBSet.galery.rawValue)"
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
        case .delete:
            return "sync/delete"
        case .moveToGalery:
            return "sync/moveFile"
        }
    }
    
    var method: STNetworkDispatcher.Method {
        switch self {
        case .moveToTrash:
            return .post
        case .delete:
            return .post
        case .moveToGalery:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .moveToTrash:
            return nil
        case .delete:
            return nil
        case .moveToGalery:
            return nil
        }
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .moveToTrash:
            return STNetworkDispatcher.Encoding.body
        case .delete:
            return STNetworkDispatcher.Encoding.body
        case .moveToGalery:
            return STNetworkDispatcher.Encoding.body
        }
    }
        
}
