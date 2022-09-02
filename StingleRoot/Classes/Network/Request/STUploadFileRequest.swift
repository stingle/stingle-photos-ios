//
//  STUploadFileRequest.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/11/21.
//

import Foundation

enum STUploadFileRequest {
    case galery(file: STLibrary.GaleryFile)
    case trash(file: STLibrary.TrashFile)
    case albumFile(file: STLibrary.AlbumFile)
}

extension STUploadFileRequest: STUploadRequest {
    
    var isBackground: Bool {
        return true
    }
        
    var files: [STUploadRequestFileInfo] {        
        switch self {
        case .galery(let file):
            if let fileThumbUrl = file.fileThumbUrl, let fileOreginalUrl = file.fileOreginalUrl  {
                let thumb = STUploadRequestFileInfo(name: "thumb", fileName: file.file, fileUrl: fileThumbUrl)
                let file = STUploadRequestFileInfo(name: "file", fileName: file.file, fileUrl: fileOreginalUrl)
                return [file, thumb]
            }
            return []
        case .trash(let file):
            if let fileThumbUrl = file.fileThumbUrl, let fileOreginalUrl = file.fileOreginalUrl  {
                let thumb = STUploadRequestFileInfo(name: "thumb", fileName: file.file, fileUrl: fileThumbUrl)
                let file = STUploadRequestFileInfo(name: "file", fileName: file.file, fileUrl: fileOreginalUrl)
                return [file, thumb]
            }
            return []
        case .albumFile(let file):
            if let fileThumbUrl = file.fileThumbUrl, let fileOreginalUrl = file.fileOreginalUrl  {
                let thumb = STUploadRequestFileInfo(name: "thumb", fileName: file.file, fileUrl: fileThumbUrl)
                let file = STUploadRequestFileInfo(name: "file", fileName: file.file, fileUrl: fileOreginalUrl)
                return [file, thumb]
            }
            return []
        }
    }

    var path: String {
        return "sync/upload"
    }

    var method: STNetworkDispatcher.Method {
        return .post
    }

    var headers: [String : String]? {
        return nil
    }

    var parameters: [String : Any]? {
        switch self {
        case .galery(let file):
            let folder = "\(file.dbSet.rawValue)"
            let token = self.token ?? ""
            let dateCreated = "\(file.dateCreated.millisecondsSince1970)"
            let dateModified = "\(file.dateModified.millisecondsSince1970)"
            let headers = file.headers
            return ["set": folder, "token": token, "dateCreated": dateCreated, "dateModified": dateModified, "headers": headers, "version": file.version]
        case .trash(let file):
            let folder = "\(file.dbSet.rawValue)"
            let token = self.token ?? ""
            let dateCreated = "\(file.dateCreated.millisecondsSince1970)"
            let dateModified = "\(file.dateModified.millisecondsSince1970)"
            let headers = file.headers
            return ["set": folder, "token": token, "dateCreated": dateCreated, "dateModified": dateModified, "headers": headers, "version": file.version]
        case .albumFile(let file):
            let folder = "\(file.dbSet.rawValue)"
            let token = self.token ?? ""
            let dateCreated = "\(file.dateCreated.millisecondsSince1970)"
            let dateModified = "\(file.dateModified.millisecondsSince1970)"
            let headers = file.headers
            return ["set": folder, "token": token, "dateCreated": dateCreated, "dateModified": dateModified, "headers": headers, "version": file.version, "albumId": file.albumId]
        }
    }

    var encoding: STNetworkDispatcher.Encoding {
        switch self {
        case .galery, .albumFile, .trash:
            return .body
        }
    }

}
