//
//  STUploadWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/11/21.
//

import Foundation

class STUploadWorker: STWorker {
    
    @discardableResult
    func upload(file: STLibrary.File, success: Success<STDBUsed>?, progress: ProgressTask? = nil, failure: Failure? = nil) -> STUploadNetworkOperation<STResponse<STDBUsed>> {
        
        if let file = file as? STLibrary.AlbumFile {
            return self.upload(file: file, success: success, progress: progress, failure: failure)
        }
        
        let request = STUploadFileRequest.file(file: file)
        return self.upload(request: request, success: success, progress: progress, failure: failure)
    }
    
    @discardableResult
    func upload(file: STLibrary.AlbumFile, success: Success<STDBUsed>?, progress: ProgressTask? = nil, failure: Failure? = nil) -> STUploadNetworkOperation<STResponse<STDBUsed>> {
        let request = STUploadFileRequest.albumFile(file: file)
        return self.upload(request: request, success: success, progress: progress, failure: failure)
    }
    
}
