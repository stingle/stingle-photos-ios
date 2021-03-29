//
//  STFileMemoryCache.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import Foundation

extension STFileRetryerManager {
        
    class MemoryCache {
        
        func retryFile(source: IRetrySource, success: @escaping RetryerSuccess<Data>, failure: @escaping RetryerFailure) {
            guard let fileData = STApplication.shared.fileSystem.contents(in: source.fileSaveUrl) else {
                failure(RetryerError.fileNotFound)
                return
            }
            success(fileData)
        }
        
        func didDownload(source: IRetrySource) throws {
            let fromUrl = source.fileTmpUrl
            let toUrl = source.fileSaveUrl
            if toUrl != fromUrl {
                try STApplication.shared.fileSystem.move(file: fromUrl, to: toUrl)
            }
        }
                
    }
        
}



