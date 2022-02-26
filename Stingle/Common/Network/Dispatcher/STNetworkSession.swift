//
//  STNetworkSession.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/3/21.
//

import Foundation
import Alamofire

class STNetworkSession: NSObject {
    
    fileprivate let rootQueue: DispatchQueue
    fileprivate var urlSession: URLSession!
        
    fileprivate var tasks = [Int: INetworkSessionTask]()
    
    init(rootQueue: DispatchQueue = DispatchQueue(label: "org.stingle.session.rootQueue", attributes: .concurrent), configuration: URLSessionConfiguration = .default) {
        self.rootQueue = rootQueue
        super.init()
        
        let operationsQueue = OperationQueue()
        operationsQueue.maxConcurrentOperationCount = 1
        operationsQueue.qualityOfService = .userInteractive
        operationsQueue.underlyingQueue = self.rootQueue
                        
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationsQueue)
    }
        
}

extension STNetworkSession {
        
    func upload(request: STNetworkUploadTask.Request, completion: @escaping (STNetworkDispatcher.Result<Data>) -> Void, progress: @escaping (Progress) -> Void) -> INetworkSessionTask {
        let taks = STNetworkUploadTask(session: self.urlSession, request: request, queue: self.rootQueue, completion: completion, progress: progress)
       
        taks.start { [weak self] urlTask in
            self?.rootQueue.async(flags: .barrier) { [weak self] in
                self?.tasks[urlTask.taskIdentifier] = taks
            }
        }
        return taks
    }
    
    func dataTask(request: STNetworkDataTask.Request, completion: @escaping (STNetworkDispatcher.Result<Data>) -> Void) -> INetworkSessionTask {
        let taks = STNetworkDataTask(session: self.urlSession, request: request, queue: self.rootQueue, completion: completion)
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
        self.tasks[task.taskIdentifier]?.urlSession(task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.tasks[task.taskIdentifier]?.urlSession(task: task, didCompleteWithError: error)
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.tasks[task.taskIdentifier] = nil
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.tasks[dataTask.taskIdentifier]?.urlSession(dataTask: dataTask, didReceive: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        self.tasks[task.taskIdentifier]?.urlSession(task: task, needNewBodyStream: completionHandler)
    }

}

extension STNetworkSession {
    
    class var backroundConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: "group.swiftlee.apps")
        configuration.httpMaximumConnectionsPerHost = 10
        configuration.sessionSendsLaunchEvents = false
        return configuration
    }
        
}
