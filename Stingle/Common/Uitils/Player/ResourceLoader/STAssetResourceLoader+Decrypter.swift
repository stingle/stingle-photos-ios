//
//  STAssetResourceLoader+Decrypter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 10/1/21.
//

import AVKit
import MobileCoreServices
import Sodium

protocol IAssetResourceLoader {
    func startRead(startOffSet: UInt64, length: UInt64, dataChunkSize: UInt64, fullDataSize: UInt64, handler: @escaping (_ chunk: Data) -> Bool, error: @escaping (Error) -> Void)
    func cancel()
}

protocol STAssetResourceLoaderDecrypterDelegate: AnyObject {
    
    func decrypter(didFinished decrypter: STAssetResourceLoader.Decrypter)
    
}

extension STAssetResourceLoader {
    
    class Decrypter {
        
        let reader: IAssetResourceLoader
        let header: STHeader
        let request: AVAssetResourceLoadingRequest
        let crypto = STApplication.shared.crypto
        
        weak var delegate: STAssetResourceLoaderDecrypterDelegate?
        
        private(set) var receiveData = Data()
        
        init(header: STHeader, reader: IAssetResourceLoader, request: AVAssetResourceLoadingRequest) {
            self.header = header
            self.reader = reader
            self.request = request
        }
        
        func start() {
            self.fillContentInformation()
            self.startLoading()
        }
        
        func cancel() {
            self.reader.cancel()
        }
        
        //MARK: - Private methods
        
        private func mimeTypeForPath(pathExtension: String) -> String {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return mimetype as String
                }
            }
            return "application/octet-stream"
        }
        
        private func fillContentInformation() {
            let filename: NSString = self.header.fileName! as NSString
            let pathExtention = filename.pathExtension
            self.request.contentInformationRequest?.contentType = self.mimeTypeForPath(pathExtension: pathExtention)
            self.request.contentInformationRequest?.isByteRangeAccessSupported = true
            self.request.contentInformationRequest?.contentLength = Int64(self.header.dataSize)
        }
        
        private func startLoading() {
            
            guard let dataRequest = self.request.dataRequest else {
                return
            }
            
            let requestedOffset = UInt64(dataRequest.requestedOffset)
            let requestedLength = UInt64(dataRequest.requestedLength)
            
            var startChankIndex = self.dataChankIndex(playerOffSet: requestedOffset)
            var startIndex = startChankIndex * self.chankSize
               
            var endChankIndex = self.dataChankIndex(playerOffSet: requestedOffset + requestedLength) + 1
            endChankIndex = min(self.chankCount, endChankIndex)
            let length = (endChankIndex - startChankIndex) * self.chankSize
                        
            startIndex = startIndex + self.startOffSetHeader
                         
            self.reader.startRead(startOffSet: startIndex, length: length, dataChunkSize: self.chankSize, fullDataSize: self.encrypedDataSize) { [weak self] chunk in
                guard let weakSelf = self else { return true }
                do {
                    let bytes = try weakSelf.crypto.decryptChunk(chunkData: Bytes(chunk), chunkNumber: startChankIndex + 1, header: weakSelf.header)
                    let data = Data(bytes)
                    startChankIndex = startChankIndex + 1
                    weakSelf.didReceiveNewData(data: data)
                } catch {
                    weakSelf.didFinishLoading(error: error)
                    return true
                }
                return false
            } error: { [weak self] error in
                self?.didFinishLoading(error: error)
            }
        }
        
        private func didReceiveNewData(data: Data) {
            self.receiveData.append(data)
            
            guard let dataRequest = self.request.dataRequest else {
                return
            }
                        
            let isFinish = self.receiveData.count >= dataRequest.requestedLength
            
            var requestedOffset = UInt64(dataRequest.requestedOffset)
            let requestedLength = UInt64(dataRequest.requestedLength)
            var currentOffset = UInt64(dataRequest.currentOffset)
            
            let startChankIndex = self.dataChankIndex(playerOffSet: requestedOffset) * self.decryptChankSize
            
            requestedOffset = requestedOffset - startChankIndex
            currentOffset = currentOffset - startChankIndex
            
            let start = currentOffset
            var end = requestedOffset + requestedLength
            
            end = min(UInt64(self.receiveData.count), end)
            guard end >= start, start < self.receiveData.count else {
                return
            }
            let range = Range(uncheckedBounds: (Int(start), Int(end)))
            let requestedDataChank = self.receiveData.subdata(in: range)
            dataRequest.respond(with: requestedDataChank)
            if isFinish {
                self.didFinishLoading(error: nil)
            }
        }
        
        private func didFinishLoading(error: Error?) {
            if let error = error {
                self.request.finishLoading(with: LoaderError.error(error: error))
                print("AssetResourceLoader", error)
            } else {
                self.request.finishLoading()
            }
            self.delegate?.decrypter(didFinished: self)
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
    
    var encrypedDataSize: UInt64 {
        return self.header.dataSize + self.startOffSetHeader + self.chankCount * 40
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
