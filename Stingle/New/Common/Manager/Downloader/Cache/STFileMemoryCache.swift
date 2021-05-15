//
//  STFileMemoryCache.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import Foundation

extension STDownloaderManager {
        
    class MemoryCache {
        
        func retryFile(source: IDownloaderSource, success: @escaping RetryerSuccess<Bool>, failure: @escaping RetryerFailure) {
            guard STApplication.shared.fileSystem.fileExists(atPath: source.fileSaveUrl.path) else {
                failure(RetryerError.fileNotFound)
                return
            }
            success(true)
        }
        
        func didDownload(source: IDownloaderSource) throws {
            let fromUrl = source.fileTmpUrl
            let toUrl = source.fileSaveUrl
            if toUrl != fromUrl {
                try STApplication.shared.fileSystem.move(file: fromUrl, to: toUrl)
            }
        }
        
        func resetCache(source: IDownloaderSource) {
            STApplication.shared.fileSystem.updateUrlDataSize(url: source.fileSaveUrl, size: 2000)
        }
                        
    }
        
}



