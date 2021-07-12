//
//  STFileWorker+Download.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/3/21.
//

import Foundation

extension STFileWorker {
    
    func getFileDownloadUrl(filename: String, dbSet: STLibrary.DBSet, success: @escaping Success<STFileUrl>, failure: @escaping Failure) {
        let request = STFileRequest.getFileDownloadUrl(filename: filename, dbSet: dbSet)
        self.request(request: request, success: success, failure: failure)
    }
    
    @discardableResult
    func stream(url: URL, offset: UInt64, length: UInt64, queue: DispatchQueue, success: @escaping Success<(requestLength: UInt64, contentLength: UInt64, range: Range<UInt64>)>, stream: @escaping StreamTask, failure: @escaping Failure) -> STStreamNetworkOperation {
        let request = STFileStreamRequest.downloadRange(url: url, offset: offset, length: length)
        return self.stream(request: request, queue: queue, success: success, stream: stream, failure: failure)
    }
    
}
