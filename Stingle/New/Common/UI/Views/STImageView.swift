//
//  STImageView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/19/21.
//

import UIKit
import Kingfisher

class STImageView: UIImageView {
    
    func setImage(_ image: IDownloaderSource?, placeholder: UIImage?) {
        let animator = STImageDownloadPlainAnimator()
        self.setImage(source: image, placeholder: placeholder, animator: animator)
    }
    
    func setImage(_ images: Images?) {
        guard let images = images else {
            self.setImage(source: images?.thumb, placeholder: nil)
            return
        }
        if let thumb = images.thumb, STApplication.shared.downloaderManager.imageRetryer.isFileExists(source: thumb) {
            self.setImage(source: images.thumb, placeholder: nil, animator: nil, success: { [weak self] _ in
                self?.setImage(source: images.original, placeholder: nil, animator: nil, saveOldImage: true)
            }, progress: nil, failure: nil)
        } else {
            self.setImage(source: images.original, placeholder: nil, animator: nil)
        }
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
        
        init?(file: STLibrary.File, isThumb: Bool) {
            guard let header = isThumb ? file.decryptsHeaders.thumb : file.decryptsHeaders.file, let imageType = ImageType(rawValue: file.dbSet.rawValue) else {
                return nil
            }
            self.fileName = file.file
            self.imageType = imageType
            self.version = file.version
            self.isThumb = isThumb
            let isThumbStr = self.isThumb ? "1" : "0"
            self.header = header
            self.imageParameters = ["file": self.fileName, "set": "\(self.imageType.rawValue)", "is_thumb": isThumbStr]
            self.isRemote = file.isRemote           
        }
        
        init?(album: STLibrary.Album, albumFile: STLibrary.AlbumFile, isThumb: Bool) {
            guard album.albumId == albumFile.albumId else {
                return nil
            }
            albumFile.updateIfNeeded(albumMetadata: album.albumMetadata)
            self.init(file: albumFile, isThumb: isThumb)
            self.imageParameters?["albumId"] = "\(album.albumId)"
        }
                
    }
    
    enum ImageType: Int {
        case file = 0
        case trash = 1
        case album = 2
    }
    
}


extension STImageView.Image: IFileRetrySource {
    
    var filePath: STFileSystem.FilesFolderType {
        let type: STFileSystem.FilesFolderType.FolderType = !self.isRemote ? .local : .cache
        let folder: STFileSystem.FilesFolderType = self.isThumb ? .thumbs(type: type) : .oreginals(type: type)
        return folder
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
