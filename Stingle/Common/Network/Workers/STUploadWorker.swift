//
//  STUploadWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/11/21.
//

import Foundation

class STUploadWorker: STWorker {
    
    @discardableResult
    func upload(file: ILibraryFile, success: Success<STDBUsed>?, progress: ProgressTask? = nil, failure: Failure? = nil) -> STUploadNetworkOperation<STResponse<STDBUsed>> {
        
        var request: STUploadFileRequest!
        
        switch file.dbSet {
        case .none:
            fatalError("implement for other classes")
        case .galery:
            request =  STUploadFileRequest.galery(file: file as! STLibrary.GaleryFile)
        case .trash:
            request =  STUploadFileRequest.trash(file: file as! STLibrary.GaleryFile)
        case .album:
            request =  STUploadFileRequest.albumFile(file: file as! STLibrary.AlbumFile)
        }
        
        return self.upload(request: request, success: success, progress: progress, failure: failure)
    }
    
}
