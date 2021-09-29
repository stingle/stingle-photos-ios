//
//  IAssetResourceNetworkFileReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/9/21.
//

import Foundation
import Sodium

extension STAssetResourceLoader {
    
    class NetworkFileReader {
        
        private let filename: String
        private let dbSet: STLibrary.DBSet
        private let queue: DispatchQueue
        private let fileWorker = STFileWorker()
        private var downloadUrl: URL?
        private var downloadChankIndexes = Set<ReadChank>()
        private var streamNetworkOperations = STObserverEvents<STStreamNetworkOperation>()
        
        var header: STHeader?
        
        private lazy var writeReadOperationQueue: STOperationQueue = {
            let operationQueue = STOperationQueue(maxConcurrentOperationCount: 1, qualityOfService: .userInteractive, underlyingQueue: self.queue)
            return operationQueue
        }()
        
        private lazy var fileHandleUrl: URL = {
            guard let url = STApplication.shared.fileSystem.url(for: .tmp) else {
                fatalError("tmpURL is nil")
            }
            let uuid = UUID().uuidString
            let result = url.appendingPathComponent(uuid)
            let data = Data()
            try? data.write(to: result)
            return result
        }()
        
        private lazy var writer: STFileHandle = {
            let fileHandle = STFileHandle(update: self.fileHandleUrl)
            return fileHandle
        }()

        private lazy var reader: STFileHandle = {
            let fileHandle = STFileHandle(read: self.fileHandleUrl)
            return fileHandle
        }()
                        
        init(filename: String, dbSet: STLibrary.DBSet, queue: DispatchQueue) {
            self.filename = filename
            self.dbSet = dbSet
            self.queue = queue
        }
        
        private func read(url: URL, startOffset: UInt64, fromOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, failure: @escaping (Error) -> Void) {
            
            self.readLocal(startOffset: startOffset, fromOffSet: fromOffSet, length: length, dataChunkSize: dataChunkSize, handler: handler, result: { [weak self] fromOffSet, length, canContinue in
                if canContinue {
                    self?.readNetwork(url: url, startOffset: startOffset, fromOffSet: fromOffSet, length: length, dataChunkSize: dataChunkSize, handler: handler, failure: failure)
                }
            }, failure: failure)
        }
        
        private func readLocal(startOffset: UInt64, fromOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, result: @escaping (_ fromOffSet: UInt64, _ length: UInt64, _ continue: Bool) -> Void, failure: @escaping (Error) -> Void) {
            
            let startChankIndex = (fromOffSet - startOffset) / dataChunkSize
            var chankIndex = startChankIndex
            
            let operations = STObserverEvents<Operation2>()
            var chanks = [ReadChank]()
            
            while true {
                guard let chank = self.downloadChankIndexes.first(where: { $0.chankIndex == chankIndex }), chank.offSet < fromOffSet + length else {
                    break
                }
                chanks.append(chank)
                chankIndex = chankIndex + 1
            }
            
            for (index, chank) in chanks.enumerated() {
                let isLast = index == chanks.count - 1
                
                let operation = Operation2(fileWriter: self.writer, fileReader: self.reader, writeData: Data(), writeOffSet: .zero, readOffSet: chank.offSet, readLength: chank.length) { responsData in
                    guard let data = responsData else {
                        return
                    }
                    let end = handler(data, chank.offSet, chank.isEnded)
                    if end || chank.isEnded || isLast {
                        operations.forEach { operation in
                            operation.cancel()
                        }
                        let endOffSet = chank.offSet + chank.length
                        let endLength = endOffSet < length + fromOffSet ? length + fromOffSet - endOffSet : .zero
                        if end {
                            operations.forEach { operation in
                                operation.cancel()
                            }
                        }
                        result(endOffSet, endLength, !end)
                    }
                    
                } failure: {  error in
                    failure(error)
                    operations.forEach { operation in
                        operation.cancel()
                    }
                }
                
                operations.addObject(operation)
                operation.didStartRun(with: self.writeReadOperationQueue)
            }
            
            if chanks.isEmpty {
                result(fromOffSet, length, true)
            }
        }
            
        private func readNetwork(url: URL, startOffset: UInt64, fromOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, failure: @escaping (Error) -> Void) {

            var writeOffset = fromOffSet
            var oldChankIndex = (writeOffset - startOffset) / dataChunkSize
            let operationQueue = self.writeReadOperationQueue
            
            self.writeReadOperationQueue.allOperations().forEach({ operation in
                (operation as? Operation2)?.cancel()
            })
            
            var streamOperation: STStreamNetworkOperation!
            streamOperation = self.fileWorker.stream(url: url, offset: fromOffSet, length: 100 * length, queue: self.queue, success: { [weak self] result in

                guard let weakSelf = self else {
                    streamOperation.cancel()
                    return
                }

                let end = result.range.lowerBound + result.requestLength
                let isFinish = end >= result.contentLength

                if isFinish {
                    
                    let offSet = oldChankIndex * dataChunkSize + startOffset
                    let readLength = result.contentLength - offSet
                    
                    let currentChankIndex = oldChankIndex
                    
                    let operation = Operation2(fileWriter: weakSelf.writer, fileReader: weakSelf.reader, writeData: Data(), writeOffSet: offSet, readOffSet: offSet, readLength: readLength) { responsData in
                        guard let data = responsData else {
                            return
                        }
                        let end = handler(data, offSet, true)
                        let readChank = ReadChank(offSet: offSet, length: readLength, chankIndex: currentChankIndex, isEnded: true)
                        weakSelf.downloadChankIndexes.insert(readChank)
                        
                        if end {
                            operationQueue.allOperations().forEach({ operation in
                                (operation as? Operation2)?.cancel()
                            })
                            streamOperation.finish()
                        }
       
                    } failure: { error in
                        failure(error)
                    }
                    operation.didStartRun(with: operationQueue)
                }
                
            }, stream: { [weak self] streamData in

                guard let weakSelf = self else {
                    streamOperation.cancel()
                    return
                }
                
                let streamDataCount = UInt64(streamData.count)
                                
                let currentWriteOffset = writeOffset
                writeOffset = writeOffset + streamDataCount
                               
                let newChankIndex = (writeOffset - startOffset) / dataChunkSize
                let oldIndex = oldChankIndex
                
                let readOffSet = oldChankIndex * dataChunkSize + startOffset
                let readOffSetEnd = newChankIndex * dataChunkSize + startOffset
                
                let readOffSetLength = readOffSetEnd - readOffSet
                oldChankIndex = newChankIndex
                
                let operation = Operation2(fileWriter: weakSelf.writer, fileReader: weakSelf.reader, writeData: streamData, writeOffSet: currentWriteOffset, readOffSet: readOffSet, readLength: readOffSetLength) { responsData in
                    guard let data = responsData else {
                        return
                    }
                                        
                    let end = handler(data, readOffSet, false)
                    let readChank = ReadChank(offSet: readOffSet, length: readOffSetLength, chankIndex: oldIndex, isEnded: false)
                    weakSelf.downloadChankIndexes.insert(readChank)
                    if end {
                        operationQueue.allOperations().forEach({ operation in
                            (operation as? Operation2)?.cancel()
                        })
                        streamOperation.finish()
                    }

                } failure: { error in
                    operationQueue.allOperations().forEach({ operation in
                        (operation as? Operation2)?.cancel()
                    })
                    failure(error)
                }
                operation.didStartRun(with: operationQueue)
                
            }, failure: failure)

            self.streamNetworkOperations.addObject(streamOperation)
        }
        
        deinit {
            self.writeReadOperationQueue.allOperations().forEach { operation in
                (operation as? Operation2)?.cancel()
            }
            self.streamNetworkOperations.forEach { operation in
                operation.cancel()
            }
            
            self.writer.close()
            self.reader.close()
            STApplication.shared.fileSystem.remove(file: self.fileHandleUrl)
        }
        
    }

}

extension STAssetResourceLoader.NetworkFileReader: IAssetResourceReader {
        
    func startRead(startOffSet: UInt64, fromOffset: UInt64, length: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void) {
       
        if let url = self.downloadUrl {
            self.read(url: url, startOffset: startOffSet, fromOffSet: fromOffset, length: length, dataChunkSize: dataChunkSize, handler: handler, failure: error)
        } else {
            self.fileWorker.getFileDownloadUrl(filename: self.filename, dbSet: self.dbSet) { [weak self] fileUrl in
                self?.downloadUrl = fileUrl.url
                self?.read(url: fileUrl.url, startOffset: startOffSet, fromOffSet: fromOffset, length: length, dataChunkSize: dataChunkSize, handler: handler, failure: error)
            } failure: { networkError in
                error(networkError)
            }
        }
    }
   
}

fileprivate extension STAssetResourceLoader.NetworkFileReader {
    
    struct ReadChank: Hashable {
        
        let offSet: UInt64
        let length: UInt64
        let chankIndex: UInt64
        let isEnded: Bool
        
        func hash(into hasher: inout Hasher) {
            return self.chankIndex.hash(into: &hasher)
        }
        
        static func == (lhs: ReadChank, rhs: ReadChank) -> Bool {
            lhs.chankIndex == rhs.chankIndex
        }
    }
    
}

fileprivate extension STAssetResourceLoader.NetworkFileReader {
    
    class Operation2: STOperation<Data?> {
        
        typealias OperationFinish = () -> Void
        
        let fileWriter: STFileHandle
        let fileReader: STFileHandle
        
        let writeData: Data
        let writeOffSet: UInt64
        
        let readOffSet: UInt64
        let readLength: UInt64
        
        init(fileWriter: STFileHandle, fileReader: STFileHandle, writeData: Data, writeOffSet: UInt64, readOffSet: UInt64, readLength: UInt64, success: @escaping STOperationSuccess, failure: @escaping STOperationFailure) {
            self.fileWriter = fileWriter
            self.fileReader = fileReader
            self.writeData = writeData
            self.writeOffSet = writeOffSet
            self.readOffSet = readOffSet
            self.readLength = readLength
            super.init(success: success, failure: failure)
        }
        
        override func resume() {
            super.resume()
            do {
                try self.write()
                let data = try self.read()
                self.responseSucces(result: data)
            } catch {
                self.responseFailed(error: STAssetResourceLoader.LoaderError.error(error: error))
            }
        }
        
        //MARK: - Private methods
        
        private func write() throws {
            guard self.writeData.count > 0 else {
                return
            }
            try self.fileWriter.write(offset: off_t(self.writeOffSet), data: self.writeData)
        }
        
        private func read() throws -> Data? {
            guard self.readLength > 0 else {
                return nil
            }
            return try self.fileReader.read(offset: off_t(self.readOffSet), length: UInt64(self.readLength))
        }
        
    }
}
