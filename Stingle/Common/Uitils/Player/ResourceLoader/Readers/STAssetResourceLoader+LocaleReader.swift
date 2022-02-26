//
//  STAssetResourceLoader+LocaleReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 10/1/21.
//

import Foundation
import Sodium

extension STAssetResourceLoader {
    
    class LocaleReader {

        let url: URL
        let queue: DispatchQueue
        
        private(set) var isCancelled: Bool = false
        
        init(url: URL, queue: DispatchQueue) {
            self.url = url
            self.queue = queue
        }
        
        lazy private var fileReader: STFileReader = {
            let result = STFileReader(fileURL: self.url)
            result.open()
            return result
        }()
        
        private func read(startOffSet: UInt64, fromOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, handler: @escaping (Data) -> Bool, error: @escaping (Error) -> Void) {
            let endOffset = min(fromOffSet + dataChunkSize, fullDataSize)
            let chankSize = endOffset - fromOffSet
            let isFinished = fromOffSet + dataChunkSize >= startOffSet + length
            self.fileReader.read(fromOffset: off_t(fromOffSet), length: off_t(chankSize), queue: self.queue) { [weak self] dispatchData in
                guard let weakSelf = self else {
                    return
                }
                guard let dispatchData = dispatchData else {
                    error(LoaderError.readError)
                    return
                }
                let readBytes = Bytes(dispatchData)
                let data = Data(readBytes)
                let isEnded = handler(data)
                
                if !isFinished && !isEnded, !weakSelf.isCancelled {
                    
                    weakSelf.read(startOffSet: startOffSet, fromOffSet: fromOffSet + dataChunkSize, length: length, dataChunkSize: dataChunkSize, fullDataSize: fullDataSize, handler: handler, error: error)
                    
                }
            }
        }
        
    }
    
}


extension STAssetResourceLoader.LocaleReader: IAssetResourceLoader {
    
    func startRead(startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, request: URLRequest, handler: @escaping (_ chunk: Data) -> Bool, error: @escaping (Error) -> Void) {
        self.read(startOffSet: startOffSet, fromOffSet: startOffSet, length: length, dataChunkSize: dataChunkSize, fullDataSize: fullDataSize, handler: handler, error: error)
    }
    
    func cancel() {
        self.isCancelled = true
    }
    
}
