//
//  STFileDownloader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import Foundation

extension STFileRetryer {
    
    class Downloader {
        
        private let operations = STObserverEvents<RetryOperation>()
        private let operationManager = STOperationManager.shared
        
//        func downloadFile(source: IRetrySource, success: @escaping RetryerSuccess<URL>, progress: @escaping RetryerProgress, failure: @escaping RetryerFailure) {
//            guard !self.operations.objects.contains(where: { $0.identifier == source.identifier}) else {
//                return
//            }
//            let operation = RetryOperation(request: source) { (url) in
//                success(url)
//            } progress: { (p) in
//                progress(p)
//            } failure: { (error) in
//                failure(error)
//            }
//            self.operationManager.run(operation: operation, in: self.operationManager.downloadQueue)
//            self.operations.addObject(operation)
//        }
        
    }

    
}
