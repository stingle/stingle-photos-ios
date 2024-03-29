//
//  STNetworkTask.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/13/22.
//

import Foundation
import Alamofire

protocol INetworkSessionTask: INetworkTask {
    var id: String { get }
    
    func urlSession(task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    func urlSession(task: URLSessionTask, didCompleteWithError error: Error?)
    func urlSession(dataTask: URLSessionDataTask, didReceive data: Data)
    func urlSession(task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void)
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) 
}

protocol INetworkTaskRequest {
    func asURLRequest() -> URLRequest
}

class STNetworkTask<UrlTask: URLSessionTask, Request: INetworkTaskRequest>: NSObject, INetworkSessionTask {
    
    private var completionTask: ((UrlTask) -> Void)?
    
    private(set) var id = UUID().uuidString
    private(set) var taskState: STNetworkDispatcher.TaskState = .running
        
    private(set) var isStarted = false
    private(set) var completion: ((STNetworkDispatcher.Result<Data>) -> Void)?
    private(set) var progress: ((Progress) -> Void)?
    
    let queue: DispatchQueue
    let session: URLSession
    let request: Request
    
    var urlTask: UrlTask? {
        didSet {
            guard let task = self.urlTask else { return }
            self.completionTask?(task)
            self.completionTask = nil
        }
    }
    
    init(session: URLSession, request: Request, queue: DispatchQueue, completion: ((STNetworkDispatcher.Result<Data>) -> Void)?, progress: ((Progress) -> Void)?) {
        self.session = session
        self.request = request
        self.queue = queue
        self.completion = completion
        self.progress = progress
    }
    
    func cancelTask() {
        self.urlTask?.cancel()
    }
    
    func suspendTask() {
        self.urlTask?.suspend()
    }
    
    func resumeTask() {
        self.urlTask?.resume()
    }
    
    func completion(with result: (STNetworkDispatcher.Result<Data>)) {
        self.completion?(result)
        self.clean()
    }
    
    func clean() {
        self.completion = nil
        self.progress = nil
        self.completionTask = nil
        self.taskState = .completed
    }
    
    func didSendBodyData(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {}
    func didCompleteWithError(error: Error?) {}
    func didReceive(data: Data) {}
    func needNewBodyStream(completionHandler: @escaping (InputStream?) -> Void) {}
    
    func didFinishDownloadingTo(location: URL) {}
    func didWriteData(bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {}
    func didResumeAtOffset(fileOffset: Int64, expectedTotalBytes: Int64) {}
            
}

extension STNetworkTask {
    
    var isCanceled: Bool {
        return self.taskState == .canceling
    }
    
    var isSuspend: Bool {
        return self.taskState == .suspended
    }
    
    var isCompleted: Bool {
        return self.taskState == .completed
    }
    
    var isRunning: Bool {
        return self.taskState == .running
    }
    
    var canContinueProcess: Bool {
        return self.taskState == .running
    }
    
    func cancel() {
        guard self.taskState == .running else {
            return
        }
        self.taskState = .canceling
        self.cancelTask()
    }
    
    func suspend() {
        guard self.taskState == .running else {
            return
        }
        self.taskState = .suspended
        self.suspendTask()
    }
    
    func resume() {
        guard self.taskState == .suspended || self.taskState == .running else {
            return
        }
        self.taskState = .running
        self.resumeTask()
    }
    
    func start(completion: ((UrlTask) -> Void)?) {
        guard !self.isStarted else {
            return
        }
        self.completionTask = completion
        self.isStarted = true
        self.resume()
    }
    
    func urlSession(task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard task.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.didSendBodyData(bytesSent: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func urlSession(task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.didCompleteWithError(error: error)
    }
    
    func urlSession(dataTask: URLSessionDataTask, didReceive data: Data) {
        guard dataTask.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.didReceive(data: data)
    }
    
    func urlSession(task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard task.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.needNewBodyStream(completionHandler: completionHandler)
    }
        
}

extension STNetworkTask {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard downloadTask.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.didFinishDownloadingTo(location: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard downloadTask.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.didWriteData(bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard downloadTask.taskIdentifier == self.urlTask?.taskIdentifier else {
            return
        }
        self.didResumeAtOffset(fileOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
    }
    
}
