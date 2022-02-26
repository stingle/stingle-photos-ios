//
//  STFileWorker+Download.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/3/21.
//

import Foundation

extension STFileWorker {
    
    func getFileDownloadUrl(filename: String, dbSet: STLibrary.DBSet, success: @escaping Success<STFileUrl>, failure: @escaping Failure) {
        let key = FileUrlKey(filename: filename, dbSet: dbSet)
        if let fileUrl = STFileWorker.fileUrlChash.object(forKey: key), !fileUrl.isExpired {
            success(STFileUrl(url: fileUrl.url))
            return
        }
        let request = STFileRequest.getFileDownloadUrl(filename: filename, dbSet: dbSet)
        self.request(request: request, success: { (responce: STFileUrl)  in
            let fileUrl = FileUrl(url: responce.url, date: Date())
            STFileWorker.fileUrlChash.setObject(fileUrl, forKey: key)
            success(responce)
        }, failure: failure)
    }
    
    @discardableResult
    func stream(url: URL, offset: UInt64, length: UInt64, queue: DispatchQueue, success: @escaping Success<(requestLength: UInt64, contentLength: UInt64, range: Range<UInt64>)>, stream: @escaping StreamTask, failure: @escaping Failure) -> STStreamNetworkOperation {
        let request = STFileStreamRequest.downloadRange(url: url, offset: offset, length: length)
        return self.stream(request: request, queue: queue, success: success, stream: stream, failure: failure)
    }
    
}


fileprivate extension STFileWorker {
    
    static var fileUrlChash = NSCache<FileUrlKey, FileUrl>()
    
    class FileUrl {
        
        let url: URL
        let date: Date
        
        init(url: URL, date: Date) {
            self.url = url
            self.date = date
        }
        
        var isExpired: Bool {
            let distance = self.date.distance(to: Date())
            return distance > 2 * 60 * 60
        }
 
    }
    
    class FileUrlKey: NSObject {
        
        let filename: String
        let dbSet: STLibrary.DBSet
        
        init(filename: String, dbSet: STLibrary.DBSet) {
            self.filename = filename
            self.dbSet = dbSet
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? FileUrlKey else {
                return false
            }
            return self.filename == other.filename && self.dbSet == other.dbSet
        }
        
        override var hash: Int {
            return self.filename.hashValue ^ self.dbSet.hashValue
        }
    
    }
    
    
}
