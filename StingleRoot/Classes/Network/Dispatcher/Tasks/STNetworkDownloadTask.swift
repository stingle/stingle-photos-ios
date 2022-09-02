//
//  STNetworkDownloadTask.swift
//  StingleRoot
//
//  Created by Khoren Asatryan on 13.07.22.
//

import Foundation

extension STNetworkDownloadTask {
    
    class Request: INetworkTaskRequest {
        
        let request: URLRequest
        let saveFileURL: URL
        
        init(request: URLRequest, saveFileURL: URL) {
            self.request = request
            self.saveFileURL = saveFileURL
        }
        
        init(url: URL, saveFileURL: URL) {
            self.request = URLRequest(url: url)
            self.saveFileURL = saveFileURL
        }
        
        func asURLRequest() -> URLRequest {
            return self.request
        }
        
    }
    
}

class STNetworkDownloadTask: STNetworkTask<URLSessionDownloadTask, STNetworkDownloadTask.Request> {
    
    override func resumeTask() {
        super.resumeTask()
        let task = self.session.downloadTask(with: self.request.request)
        self.urlTask = task
        task.resume()
    }
    
    override func didCompleteWithError(error: Error?) {
        super.didCompleteWithError(error: error)
        if let error = error {
            self.completion(with: .failure(error: STNetworkDispatcher.NetworkError.error(error: error)))
        } else {
            self.completion(with: .success(result: Data()))
        }
    }
    
    override func didReceive(data: Data) {
        super.didReceive(data: data)
    }
    
}


