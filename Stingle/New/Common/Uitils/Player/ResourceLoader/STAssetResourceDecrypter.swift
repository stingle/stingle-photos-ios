//
//  STAssetResourceDecrypter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/5/21.
//

import Sodium

extension STAssetResourceLoader {
    
    class Decrypter {
        
        private let reader: IAssetResourceReader
        private let header: STHeader
        private let fileReader: STFileHandle!
        
        private let crypto = STApplication.shared.crypto
        private var decrypChankIndexes = Set<UInt64>()
        
        init?(header: STHeader, reader: IAssetResourceReader) {

            guard var url = STApplication.shared.fileSystem.tmpURL?.appendingPathComponent("VideoDecryp"), let name = header.fileName else {
                return nil
            }
            do {
                try STApplication.shared.fileSystem.createDirectory(url: url)
            } catch {
                return nil
            }
            
            let decrypName = UUID().uuidString + name
            url.appendPathComponent(decrypName)
            guard let fileReader = Self.createFileRead(url: url) else {
                return nil
            }
            self.fileReader = fileReader
            self.reader = reader
            self.header = header
        }
        
        func startDecrypter(requestedOffset: UInt64, handler: @escaping (_ data: Data, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void) {
            var ended = false
            self.readData(requestedOffset: requestedOffset) { readData, finish in
                ended = handler(readData, finish) || finish
                return ended
            } error: { receiveError in
                error(receiveError)
                return
            }
            guard !ended else {
                return
            }
            
        }
                
        //MARK: - Private methods
        
        private func readData(requestedOffset: UInt64, handler: @escaping (_ data: Data, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void) {
            
            let decrypDataChunkSize = self.decryptChankSize
            let startChankIndex = self.dataChankIndex(playerOffSet: requestedOffset)
            
            var currentChankIndex = startChankIndex
            let chankCounts = self.chankCount
            var resultData = Data()
            
            func didReciveNewChank(data: Data, currentChankIndex: UInt64) -> Bool {
                if currentChankIndex ==  startChankIndex {
                    let startOffset = requestedOffset - decrypDataChunkSize * currentChankIndex
                    let range = Range(uncheckedBounds: (Int(startOffset), Int(data.count)))
                    let requestedDataChank = data.subdata(in: range)
                    resultData.append(requestedDataChank)
                } else {
                    resultData.append(data)
                }
                let finish = currentChankIndex == chankCounts - 1
                let end = handler(resultData, finish)
                return end
            }

            let chankSize = self.chankSize
            let requestedOffset = currentChankIndex * chankSize
            self.readEncrypedData(requestedOffset: requestedOffset, handler: { readData, chankIndex, finish in
                let finish = didReciveNewChank(data: readData, currentChankIndex: currentChankIndex)
                currentChankIndex = currentChankIndex + 1
                return finish
            }, errorHandler: error)
        }
        
        private func readEncrypedData(requestedOffset: UInt64, handler: @escaping (_ data: Data, _ chankIndex: UInt64, _ finish: Bool) -> Bool, errorHandler: @escaping (Error) -> Void) {
            
            var requestedOffset = self.dataOffset(playerOffSet: requestedOffset)
            let chankIndex = self.dataChankIndex(encriptOffSet: requestedOffset)
            let chankSize = self.chankSize
            
            requestedOffset = chankSize * chankIndex + self.startOffSetHeader
                        
            self.reader.startRead(startOffset: requestedOffset, dataChunkSize: chankSize) { [weak self] readData, fromOffset, finish in
                guard let weakSelf = self else {
                    return false
                }
                let chankIndex = weakSelf.dataChankIndex(encriptOffSet: fromOffset)
                do {
                    let chunkBytes = Bytes(readData)
                    let decryptBytes = try weakSelf.crypto.decryptChunk(chunkData: chunkBytes, chunkNumber: chankIndex + 1, header: weakSelf.header)
                    let decryptData = Data(decryptBytes)
                    return handler(decryptData, chankIndex, finish)
                } catch {
                    errorHandler(LoaderError.error(error: error))
                    return true
                }
            } error: { receiveError in
                errorHandler(receiveError)
            }
        }
        
        //MARK: - Deinit
        
        deinit {
            self.fileReader.close()
        }
        
                        
    }
    
}

fileprivate extension STAssetResourceLoader.Decrypter {
    
    var chankCount: UInt64 {
        let count = Double(self.header.dataSize) / Double(self.decryptChankSize)
        return UInt64(ceil(count))
    }
    
    var chankSize: UInt64 {
        return UInt64(self.crypto.chunkSizeForHeader(header: self.header))
    }
    
    var decryptChankSize: UInt64 {
        return self.chankSize - 40
    }
    
    var startOffSetHeader: UInt64 {
        return UInt64(self.crypto.startOffSet(header: self.header))
    }
    
    func dataChankIndex(encriptOffSet: UInt64) -> UInt64 {
        let chankSize = UInt64(self.crypto.chunkSizeForHeader(header: self.header))
        let headerOffset = UInt64(self.crypto.startOffSet(header: self.header))
        let offset = encriptOffSet - headerOffset
        let fromOffSetIndex = UInt64((Double(offset) / Double(chankSize)))
        return fromOffSetIndex
    }
    
    func dataChankIndex(playerOffSet: UInt64) -> UInt64 {
        let headerOffset = UInt64(self.crypto.startOffSet(header: self.header))
        let dataOffset = UInt64(self.dataOffset(playerOffSet: playerOffSet)) - headerOffset
        let chankSize = UInt64(self.crypto.chunkSizeForHeader(header: self.header))
        let chankIndex = UInt64((Double(dataOffset) / Double(chankSize)))
        return chankIndex
    }
    
    func dataOffset(playerOffSet: UInt64) -> UInt64 {
        let playerOffSet = UInt64(playerOffSet)
        let chankSize = UInt64(self.crypto.chunkSizeForHeader(header: self.header))
        let decryptChankSize = self.decryptChankSize
        let headerOffset = UInt64(self.crypto.startOffSet(header: self.header))
        let chankIndex = UInt64((Double(playerOffSet) / Double(decryptChankSize)))
        let diff = playerOffSet - chankIndex * decryptChankSize
        let encriptOffSetChankIndex = chankIndex * chankSize + diff + chankSize - decryptChankSize
        return UInt64(encriptOffSetChankIndex + headerOffset)
    }
    
    func dataOffset(encriptOffSet: UInt64) -> UInt64 {
        let chankSize = self.chankSize
        let decryptChankSize = self.decryptChankSize
        let headerOffset = UInt64(self.crypto.startOffSet(header: self.header))
        let startEncriptOffSet = encriptOffSet - headerOffset
        let chankIndex = UInt64((Double(startEncriptOffSet) / Double(chankSize)))
        let chankDiff = chankSize - decryptChankSize
        return startEncriptOffSet - UInt64(chankDiff * chankIndex)
    }
    
}

fileprivate extension STAssetResourceLoader.Decrypter {
    
    private class func createFileRead(url: URL) -> STFileHandle? {
        return STFileHandle(read: url)
    }
    
    
}
