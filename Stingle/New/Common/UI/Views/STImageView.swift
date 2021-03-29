//
//  STImageView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/19/21.
//

import UIKit
import Kingfisher

class STImageView: UIImageView {
    
    func setImage(_ image: Image?, placeholder: UIImage?) {
        let animator = STImageDownloadPlainAnimator()
        self.setImage(source: image, placeholder: placeholder, animator: animator)
    }

}


extension STImageView {
    
    struct Image {
            
        let fileName: String
        let imageType: ImageType
        let version: String
        let isThumb: Bool
        
        let imageParameters: [String : Any]?
        let header: STHeader
        
        init?(file: STLibrary.File, isThumb: Bool) {
            guard let header = isThumb ? file.encryptsHeaders.thumb : file.encryptsHeaders.file else {
                return nil
            }
            self.fileName = file.file
            self.imageType = .file
            self.version = file.version
            self.isThumb = isThumb
            let isThumbStr = self.isThumb ? "1" : "0"
            self.header = header
            self.imageParameters = ["file": self.fileName, "set": "\(self.imageType.rawValue)", "is_thumb": isThumbStr]
        }
                
    }
    
    enum ImageType: Int {
        case file = 0
        case trash = 1
        case album = 2
    }
    
}


extension STImageView.Image: IRetrySource {
    
    var filePath: String {
        return self.isThumb ? "Thumb" : "Oreginal"
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
