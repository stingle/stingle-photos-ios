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
        let request = STUploadFileRequest.file(file: file)
        return self.upload(request: request, success: success, progress: progress, failure: failure)
    }
    
}
