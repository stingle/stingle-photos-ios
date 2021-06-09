//
//  STPLayerLocalFileReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/5/21.
//

import Sodium

protocol IAssetResourceReader {
    
    func startRead(startOffset: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void)
    
}

extension STAssetResourceLoader {
    
    class LocalFileReader {
        
        let url: URL
        let queue: DispatchQueue
                
        lazy private var fileReader: STFileReader = {
            let result = STFileReader(fileURL: self.url)
            result.open()
            return result
        }()
        
        init(url: URL, queue: DispatchQueue) {
            self.url = url
            self.queue = queue
        }
        
        //MARK: - Private methods
                
        private func read(startOffset: UInt64, offset: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void) {
            
            let fullSize = UInt64(self.fileReader.fullSize)
            let offset = min(offset, fullSize)
            
            guard dataChunkSize > .zero else {
                let _ = handler(Data(), offset, true)
                return
            }
                        
            let finish = offset + dataChunkSize >= fullSize
            self.fileReader.read(fromOffset: off_t(offset), length: off_t(dataChunkSize), queue: self.queue) { [weak self] dispatchData in
                guard let weakSelf = self, let dispatchData = dispatchData else {
                    error(LoaderError.readError)
                    return
                }
                let readBytes = Bytes(dispatchData)
                let data = Data(readBytes)
                let end = handler(data, offset, finish)
                if !finish && !end {
                    let nextOffset = offset + dataChunkSize
                    weakSelf.queue.async {
                        weakSelf.read(startOffset: startOffset, offset: nextOffset, dataChunkSize: dataChunkSize, handler: handler, error: error)
                    }
                }
            }
        }
        
    }
    
}

extension STAssetResourceLoader.LocalFileReader: IAssetResourceReader {
    
    func startRead(startOffset: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void) {
        self.read(startOffset: startOffset, offset: startOffset, dataChunkSize: dataChunkSize, handler: handler, error: error)
    }
    
}
