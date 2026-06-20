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
            request =  STUploadFileRequest.trash(file: file as! STLibrary.TrashFile)
        case .album:
            request =  STUploadFileRequest.albumFile(file: file as! STLibrary.AlbumFile)
        }
        
        return self.upload(request: request, success: success, progress: progress, failure: failure)
    }

}

//MARK: - async/await

extension STUploadWorker {

    func upload(file: ILibraryFile, progress: ProgressTask? = nil) async throws -> STDBUsed {
        return try await withCheckedThrowingContinuation { continuation in
            self.upload(file: file, success: { continuation.resume(returning: $0) },
                        progress: progress,
                        failure: { continuation.resume(throwing: $0) })
        }
    }

}
