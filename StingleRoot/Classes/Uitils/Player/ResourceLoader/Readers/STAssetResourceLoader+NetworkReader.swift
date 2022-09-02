//
//  STAssetResourceLoader+NetworkReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 10/3/21.
//

import Foundation

extension STAssetResourceLoader {
    
    class NetworkReader {
        
        let queue: DispatchQueue
        let filename: String
        let dbSet: STLibrary.DBSet
        private(set) var streemUrl: URL?
        private let fileWorker = STFileWorker()
        private var streamOperation: STStreamNetworkOperation?
        private(set) var receiveData = Data()
        private(set) var receiveCount: UInt64 = .zero
        private let networkSession: STNetworkSession
        private(set) var request: URLRequest?
        private var sessionTask: INetworkSessionTask?
        
        init(filename: String, dbSet: STLibrary.DBSet, queue: DispatchQueue, networkSession: STNetworkSession) {
            self.networkSession = networkSession
            self.filename = filename
            self.dbSet = dbSet
            self.queue = queue
        }
        
        //MARK: - Private methods
        
        private func read(url: URL, startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, handler: @escaping (Data) -> Bool, failure: @escaping (Error) -> Void) {
            var taskRequest: STNetworkDataTask.Request!
            if let request = self.request {
                taskRequest = STNetworkDataTask.Request(request: request, offset: startOffSet, length: length, url: url)
            } else {
                taskRequest = STNetworkDataTask.Request(offset: startOffSet, length: length, url: url)
            }
            self.sessionTask = self.networkSession.dataTask(request: taskRequest) { [weak self] result in
                switch result {
                case .failure(let error):
                    if !error.isCancelled {
                        failure(error)
                    }
                case .success(let data):
                    self?.queue.async(flags: .barrier) { [weak self] in
                        self?.didReceiveNewData(data, startOffSet: startOffSet, length: length, dataChunkSize: dataChunkSize, fullDataSize: fullDataSize, handler: handler)
                    }
                }
            }
        }
        
        //MARK: - Private
        
        private func didReceiveNewData(_ data: Data, startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, handler: @escaping (Data) -> Bool) {
            self.receiveData.append(data)
            self.receiveCount = self.receiveCount + UInt64(data.count)
            let currentChankIndex = UInt64(self.receiveData.count) / dataChunkSize
            let endIndex = self.receiveCount + startOffSet
            let isEndChank = endIndex >= fullDataSize || currentChankIndex == 1
            if isEndChank {
                                
                let start: UInt64 = .zero
                let end = min(UInt64(self.receiveData.count), dataChunkSize)
                let range = Range(uncheckedBounds: (Int(start), Int(end)))
                let requestedDataChank = self.receiveData.subdata(in: range)
                
                let myDataRange = Range(uncheckedBounds: (Int(end), Int(self.receiveData.count)))
                self.receiveData = self.receiveData.subdata(in: myDataRange)
                                
                self.queue.async { [weak self] in
                    let ended = handler(requestedDataChank)
                    if ended {
                        self?.sessionTask?.cancel()
                    }
                }
            }
        }
        
        deinit {
            self.sessionTask?.cancel()
            self.streamOperation?.cancel()
        }
        
    }

}

extension STAssetResourceLoader.NetworkReader: IAssetResourceLoader {
    
    func startRead(startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, request: URLRequest, handler: @escaping (_ chunk: Data) -> Bool, error: @escaping (Error) -> Void) {
        self.request = request
        if let streemUrl = self.streemUrl {
            self.read(url:streemUrl, startOffSet: startOffSet, length: length, dataChunkSize: dataChunkSize, fullDataSize: fullDataSize, handler: handler, failure: error)
        } else {
            self.fileWorker.getFileDownloadUrl(filename: self.filename, dbSet: self.dbSet, success: { [weak self] result in
                self?.read(url: result.url, startOffSet: startOffSet, length: length, dataChunkSize: dataChunkSize, fullDataSize: fullDataSize, handler: handler, failure: error)
            }, failure: error)
        }
        
    }
    
    func cancel() {
        self.streamOperation?.cancel()
        self.sessionTask?.cancel()
    }
    
}
