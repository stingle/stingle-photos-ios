//
//  STAssetResourceLoader1+NetworkReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 10/3/21.
//

import Foundation

extension STAssetResourceLoader1 {
    
    class NetworkReader {
        
        let queue: DispatchQueue
        let filename: String
        let dbSet: STLibrary.DBSet
        private(set) var streemUrl: URL?
        private let fileWorker = STFileWorker()
        private var streamOperation: STStreamNetworkOperation?
        private(set) var receiveData = Data()
        private(set) var receiveCount: UInt64 = .zero
        
        init(filename: String, dbSet: STLibrary.DBSet, queue: DispatchQueue) {
            self.filename = filename
            self.dbSet = dbSet
            self.queue = queue
        }
        
        //MARK: - Private methods
        
        private func read(url: URL, startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, handler: @escaping (Data) -> Bool, failure: @escaping (Error) -> Void) {
            self.streamOperation = self.fileWorker.stream(url: url, offset: startOffSet, length: length, queue: self.queue) { result in
            } stream: { [weak self] progress in
                self?.queue.async(flags: .barrier) { [weak self] in
                    self?.didReceiveNewData(progress, startOffSet: startOffSet, length: length, dataChunkSize: dataChunkSize, fullDataSize: fullDataSize, handler: handler)
                }
            } failure: { error in
                if !error.isCancelled {
                    failure(error)
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
                self.queue.async {
                    let ended = handler(requestedDataChank)
                    if ended {
                        self.streamOperation?.cancel()
                    }
                }
            }
        }
        
        deinit {
            self.streamOperation?.cancel()
        }
        
    }
    
        
}


extension STAssetResourceLoader1.NetworkReader: IAssetResourceLoader {
    
    func startRead(startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, handler: @escaping (Data) -> Bool, error: @escaping (Error) -> Void) {
        
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
    }
    
}
