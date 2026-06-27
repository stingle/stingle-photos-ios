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
            let reachedEndOfData = (self.receiveCount + startOffSet) >= fullDataSize
            let chunkSize = Int(dataChunkSize)

            // Emit every *complete* encrypted chunk, in order. The Decrypter derives each
            // chunk's key from its sequence number, so chunks must arrive whole and
            // ordered. The previous logic only emitted when exactly one chunk was buffered
            // (`receiveData.count / chunkSize == 1`); a single network delivery that
            // buffered two or more chunks at once skipped past that test and the read hung
            // forever — the cause of "some videos load forever from the server". Draining
            // in a loop (and calling the handler synchronously on this queue) also removes
            // the prior out-of-order hazard of dispatching each handler async onto a
            // concurrent queue.
            while self.receiveData.count >= chunkSize {
                let chunk = self.takeReceivedData(upTo: chunkSize)
                if handler(chunk) {
                    self.sessionTask?.cancel()
                    return
                }
            }
            // The file's final chunk is shorter than a full chunk; flush it once every
            // byte of the requested range has arrived.
            if reachedEndOfData, !self.receiveData.isEmpty {
                let chunk = self.takeReceivedData(upTo: self.receiveData.count)
                _ = handler(chunk)
            }
        }

        private func takeReceivedData(upTo size: Int) -> Data {
            let chunk = self.receiveData.subdata(in: 0 ..< size)
            self.receiveData = self.receiveData.subdata(in: size ..< self.receiveData.count)
            return chunk
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
