//
//  STNetworkSession.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/3/21.
//

import Foundation

protocol INetworkSessionEvent: AnyObject {
    func networkSession(networkSession: STNetworkSession, didReceive data: Data)
}

class STNetworkSession: NSObject {
    
    fileprivate let rootQueue: DispatchQueue
    fileprivate var urlSession: URLSession!
    fileprivate var tasks = [Int: INetworkSessionTask]()
    
    weak var sessionEvent: INetworkSessionEvent?
    
    init(rootQueue: DispatchQueue = DispatchQueue(label: "org.stingle.session.rootQueue", attributes: .concurrent), configuration: URLSessionConfiguration = .default) {
        self.rootQueue = rootQueue
        super.init()
        
        let operationsQueue = OperationQueue()
        operationsQueue.maxConcurrentOperationCount = 10
        operationsQueue.qualityOfService = .userInteractive
        operationsQueue.underlyingQueue = self.rootQueue
                        
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationsQueue)
    }
        
}

extension STNetworkSession {
        
    @discardableResult func upload(request: STNetworkUploadTask.Request, completion: @escaping (STNetworkDispatcher.Result<Data>) -> Void, progress: @escaping (Progress) -> Void) -> INetworkSessionTask {
        let taks = STNetworkUploadTask(session: self.urlSession, request: request, queue: self.rootQueue, completion: completion, progress: progress)
       
        taks.start { [weak self] urlTask in
            self?.rootQueue.async(flags: .barrier) { [weak self] in
                self?.tasks[urlTask.taskIdentifier] = taks
            }
        }
        return taks
    }
    
    @discardableResult func dataTask(request: STNetworkDataTask.Request, completion: @escaping (STNetworkDispatcher.Result<Data>) -> Void) -> INetworkSessionTask {
        let taks = STNetworkDataTask(session: self.urlSession, request: request, queue: self.rootQueue, completion: completion)
        taks.start { [weak self] urlTask in
            self?.rootQueue.async(flags: .barrier) { [weak self] in
                self?.tasks[urlTask.taskIdentifier] = taks
            }
        }
        return taks
    }
    
    @discardableResult func downloadTask(request: STNetworkDownloadTask.Request, completion: @escaping (STNetworkDispatcher.Result<Data>) -> Void, progress: @escaping (Progress) -> Void) -> INetworkSessionTask {
        let taks = STNetworkDownloadTask(session: self.urlSession, request: request, queue: self.rootQueue, completion: completion, progress: progress)
        taks.start { [weak self] urlTask in
            self?.rootQueue.async(flags: .barrier) { [weak self] in
                self?.tasks[urlTask.taskIdentifier] = taks
            }
        }
        return taks
    }
    
    @discardableResult func downloadTask(url: URL, saveFileURL: URL, completion: @escaping (STNetworkDispatcher.Result<Data>) -> Void, progress: @escaping (Progress) -> Void) -> INetworkSessionTask {
        let request = STNetworkDownloadTask.Request(url: url, saveFileURL: saveFileURL)
        let taks = STNetworkDownloadTask(session: self.urlSession, request: request, queue: self.rootQueue, completion: completion, progress: progress)
        taks.start { [weak self] urlTask in
            self?.rootQueue.async(flags: .barrier) { [weak self] in
                self?.tasks[urlTask.taskIdentifier] = taks
            }
        }
        return taks
    }
    
}

extension STNetworkSession: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[task.taskIdentifier]?.urlSession(task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.tasks[task.taskIdentifier]?.urlSession(task: task, didCompleteWithError: error)
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[task.taskIdentifier] = nil
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.sessionEvent?.networkSession(networkSession: self, didReceive: data)
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[dataTask.taskIdentifier]?.urlSession(dataTask: dataTask, didReceive: data)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[task.taskIdentifier]?.urlSession(task: task, needNewBodyStream: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[downloadTask.taskIdentifier]?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[downloadTask.taskIdentifier]?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[downloadTask.taskIdentifier]?.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        }
    }
    
}

extension STNetworkSession {
    
    static let `default` = STNetworkSession(configuration: URLSessionConfiguration.default)
    
    class var backroundConfiguration: URLSessionConfiguration {
        let appBundleName = Bundle.main.bundleURL.lastPathComponent.lowercased().replacingOccurrences(of: " ", with: ".")
        let sessionIdentifier: String = "com.networking.\(appBundleName)"
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.sharedContainerIdentifier = "group.\(STEnvironment.current.appFileSharingBundleId)"
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }
    
    class var avStreamingConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.networkServiceType = .avStreaming
        return configuration
    }
            
}
