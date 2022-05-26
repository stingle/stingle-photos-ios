//
//  STImageView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/19/21.
//

import UIKit

class STImageView: UIImageView {
    
    func setImage(_ image: IDownloaderSource?, placeholder: UIImage?, success: ISuccess? = nil, progress: IProgress? = nil, failure: IFailure? = nil) {
        let animator = STImageDownloadPlainAnimator()
        self.setImage(source: image, placeholder: placeholder, animator: animator, success: success, progress: progress, failure: failure)
    }
    
    deinit {
        guard let retryerIdentifier = self.retryerIdentifier else {
            return
        }
        Self.imageRetryer.cancel(operation: retryerIdentifier)
    }
    
}

extension STImageView {
    
    struct Images {
        let thumb: Image?
        let original: Image?
    }
    
    struct Image {
            
        let fileName: String
        let imageType: ImageType
        let version: String
        let isThumb: Bool
        let isRemote: Bool
        
        private(set) var imageParameters: [String : Any]?
        let header: STHeader
        
        init?(file: ILibraryFile?, isThumb: Bool) {
            guard let file = file, let header = isThumb ? file.decryptsHeaders.thumb : file.decryptsHeaders.file, let imageType = ImageType(rawValue: file.dbSet.rawValue) else {
                return nil
            }
            self.fileName = file.file
            self.imageType = imageType
            self.version = file.version
            self.isThumb = isThumb
            self.header = header
            self.imageParameters = file.getImageParameters(isThumb: self.isThumb)
            self.isRemote = file.isRemote && file.isSynched
        }
        
        init?(album: STLibrary.Album?, albumFile: STLibrary.AlbumFile?, isThumb: Bool) {
            guard let album = album, let albumFile = albumFile, album.albumId == albumFile.albumId else {
                return nil
            }
            albumFile.updateIfNeeded(albumMetadata: album.albumMetadata)
            self.init(file: albumFile, isThumb: isThumb)
        }
                
    }
    
    enum ImageType: Int {
        case file = 0
        case trash = 1
        case album = 2
    }
    
}

extension STImageView.Image: IFileRetrySource {
    
    var folderType: STFileSystem.FolderType {
        let fileType: STFileSystem.FileType = self.isThumb ? .thumbs : .oreginals
        if self.isRemote {
            return STFileSystem.FolderType.storage(type: .server(type: fileType))
        } else {
            return STFileSystem.FolderType.storage(type: .local(type: fileType))
        }
    }
    
}

extension STImageView.Image: STDownloadRequest {
    
    var parameters: [String : Any]? {
        var parameters = self.imageParameters
        parameters?.addIfNeeded(key: "token", value: self.token)
        return parameters
    }
    
    var path: String {
        return "sync/downloadRedir"
    }
    
    var method: STNetworkDispatcher.Method {
        .post
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var encoding: STNetworkDispatcher.Encoding {
        return STNetworkDispatcher.Encoding.body
    }
       
}
