//
//  STNetworkStreamTask.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/22/22.
//

import Foundation

class STNetworkDataTask: STNetworkTask<URLSessionDataTask, STNetworkDataTask.Request> {
    
    init(session: URLSession, request: Request, queue: DispatchQueue, completion: ((STNetworkDispatcher.Result<Data>) -> Void)?) {
        super.init(session: session, request: request, queue: queue, completion: completion, progress: nil)
    }
    
    override func resumeTask() {
        super.resumeTask()
        let task = self.session.dataTask(with: self.request.asURLRequest())
        self.urlTask = task
        task.resume()
    }
    
    override func didReceive(data: Data) {
        super.didReceive(data: data)
        self.completion?(.success(result: data))
    }
    
    override func didCompleteWithError(error: Error?) {
        super.didCompleteWithError(error: error)
        if let error = error {
            self.completion(with: .failure(error: .error(error: error)))
        } else {
            self.completion(with: .success(result: Data()))
        }
    }

}

extension STNetworkDataTask {
    
    class Request: INetworkTaskRequest {
        
        let request: URLRequest
        
        init(request: URLRequest) {
            self.request = request
        }
        
        convenience init(request: URLRequest, offset: UInt64, length: UInt64, url: URL) {
            var request = request
            request.url = url
            let range = "bytes=\(offset)-\(offset + length - 1)"
            request.setValue(range, forHTTPHeaderField: "Range")
            self.init(request: request)
        }
        
        convenience init(offset: UInt64, length: UInt64, url: URL) {
            var request = URLRequest(url: url)
            let range = "bytes=\(offset)-\(offset + length - 1)"
            request.setValue(range, forHTTPHeaderField: "Range")
            self.init(request: request)
        }
                
        func asURLRequest() -> URLRequest {
            return self.request
        }
        
    }
    
}
