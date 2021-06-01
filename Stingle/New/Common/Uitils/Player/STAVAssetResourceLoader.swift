//
//  STAVAssetResourceLoader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import AVKit
import Sodium
import MobileCoreServices

fileprivate extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
    
}

class STAssetResourceLoader: NSObject {
    
    enum Scheme {
        case file
        case url(name: String)
        
        init(identifier: String) {
            switch identifier {
            case Scheme.file.identifier:
                self = Scheme.file
            default:
                self = Scheme.url(name: identifier)
            }
        }
        
        var identifier: String {
            switch self {
            case .file:
                return "file"
            case .url(let name):
                return name
            }
        }
        
    }
    
    let asset: AVURLAsset
    let url: URL
    
    private let cachingScheme = "STAssetScheme"
    private let scheme: Scheme
    private let fileExtension: String?
    private let header: STHeader
    private let dispatchQueue = DispatchQueue.main//(label: "Player.Queue", attributes: .concurrent)
    private let operationManager = STOperationManager.shared
    
    lazy private var operationQueue: STOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 100, underlyingQueue: self.dispatchQueue)
        return queue
    }()
    
    
    lazy private var fileReader: STFileReader = {
        let result = STFileReader(fileURL: self.url)
        result.open()
        return result
    }()
    
    init(with url: URL, header: STHeader, fileExtension: String?) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              var urlWithCustomScheme = url.withScheme(self.cachingScheme) else {
            fatalError("Urls without a scheme are not supported")
        }
        
        if let name = header.fileName as NSString?, !name.pathExtension.isEmpty {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(name.pathExtension)
        }
        
        self.header = header
        self.asset = AVURLAsset(url: urlWithCustomScheme)
        self.url = url
        self.scheme = Scheme(identifier: scheme)
        self.fileExtension = fileExtension
        super.init()
        self.asset.resourceLoader.setDelegate(self, queue: self.dispatchQueue)
        
    }
    
}

extension STAssetResourceLoader: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if let operation = self.operation(for: loadingRequest) {
            operation.updateLoadingRequest(loadingRequest: loadingRequest)
            return true
        }        
        let operation = LocalFileOperation(loadingRequest: loadingRequest, localUrl: self.url, fileReader: fileReader, header: self.header)
        self.operationManager.run(operation: operation, in: self.operationQueue)
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        
        if let operation = self.operation(for: loadingRequest) {
            operation.cancel()
        }
        
    }
    
    
    func operation(for loadingRequest: AVAssetResourceLoadingRequest) -> Operation? {
        for operation in self.operationQueue.allOperations() {
            
            if let operation = operation as? Operation, operation.loadingRequest == loadingRequest {
                return operation
            }
        }
        
        return nil
    }
    
}

extension STAssetResourceLoader {
    
    class Operation: STOperation<Data> {
        
        let loadingRequest: AVAssetResourceLoadingRequest
        let crypto = STApplication.shared.crypto
        
        init(loadingRequest: AVAssetResourceLoadingRequest) {
            self.loadingRequest = loadingRequest
            super.init(success: nil, failure: nil)
        }
        
        // MARK: - override
        
        override func resume() {
            super.resume()
            self.loadData()
        }
        
        // MARK: - Public override
        
        func loadData() {
            
        }
        
        func updateLoadingRequest(loadingRequest: AVAssetResourceLoadingRequest) {
            print("")
        }
        
        func mimeTypeForPath(pathExtension: String) -> String {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return mimetype as String
                }
            }
            return "application/octet-stream"
        }
        
        override func responseSucces(result: Any) {
            self.loadingRequest.finishLoading()
            super.responseSucces(result: result)
        }
        
        
    }
    
    class LocalFileOperation: Operation {
        
        let url: URL
        let header: STHeader
        
        static var dataSize: Int64 = 100
        
        private var mediaData = Data()
        
        lazy var fileReader: LocalFileReader? = {
            guard let dataRequest = self.loadingRequest.dataRequest else {
                return nil
            }
            
            let queue = self.delegate?.underlyingQueue ?? .main
            let chunkSize = self.crypto.chunkSizeForHeader(header: self.header)
            let fromOffsetIndex = Int(self.dataRequestedOffset / chunkSize)
            let fromOffset = off_t(fromOffsetIndex) * chunkSize + self.crypto.startOffSet(header: self.header)
            let chunkCount: off_t = off_t(ceil(Double(self.dataRequestRequestedLength) / Double(chunkSize)))
            var length = chunkCount * chunkSize
            let fileReader = LocalFileReader(url: self.url, dataChunkSize: chunkSize, offset: fromOffset, length: length, queue: queue)
            
            return fileReader
        }()
                
        var dataRequestCurrentOffset: off_t {
            return self.loadingRequest.dataRequest?.currentOffset ?? .zero
        }
        
        var dataRequestedOffset: off_t {
            return self.loadingRequest.dataRequest?.requestedOffset ?? .zero
        }
        
        var dataRequestRequestedLength: off_t {
            return off_t(self.loadingRequest.dataRequest?.requestedLength ?? .zero)
        }
        
        
        init(loadingRequest: AVAssetResourceLoadingRequest, localUrl: URL, fileReader: STFileReader, header: STHeader) {
            self.url = localUrl
            self.header = header
            super.init(loadingRequest: loadingRequest)
        }
        
        override func loadData() {
            super.loadData()
            
            self.loadDataTest3()
            
            
//            let data = STApplication.shared.fileSystem.contents(in: self.url)
//
//
//            let vvvv = try! self.crypto.decryptData(data: data!, header: self.header)
//
//            let bbbb = Bytes(vvvv)
//
//            self.loadDataTest(decryptDataBytesOr: bbbb)
            
            
        }
        
        deinit {
            print("")
        }
        
        func loadDataTest3() {
            guard let dataRequest = self.loadingRequest.dataRequest, let localFileReader = self.fileReader else {
                return
            }
            self.fillContentInformation()
            let chankSize = UInt64(self.crypto.chunkSizeForHeader(header: self.header))
            let requestedLength = self.dataRequestRequestedLength
            let headerOffset = off_t(self.crypto.startOffSet(header: self.header))
            
            
            func firstChankOffset() -> off_t{
                let startChankIndex = UInt64((Double(localFileReader.offset - headerOffset) / Double(chankSize)))
                let currentOffset: UInt64 = UInt64(self.dataRequestCurrentOffset)
                let firstChankOffset = off_t(currentOffset - startChankIndex * (chankSize - 40))
                return firstChankOffset
            }
            
            func dataRequestedOffset() -> off_t{
                let startChankIndex = UInt64((Double(localFileReader.offset - headerOffset) / Double(chankSize)))
                let currentOffset: UInt64 = UInt64(self.dataRequestedOffset)
                let firstChankOffset = off_t(currentOffset - startChankIndex * (chankSize - 40))
                return firstChankOffset
            }
                        
            var myChankIndex: Int = .zero
            var decryptedFullData = Data()
            
            localFileReader.startRead { [weak self] data, startOffset, fromOffset, _, finish in
                guard let weakSelf = self, !weakSelf.isExpired else {
                    return
                }
                
                let firstChankOffset = firstChankOffset()
                
                
                let offset = fromOffset - headerOffset
                let fromOffSetIndex = UInt64((Double(offset) / Double(chankSize)))
                let chunkNumber = fromOffSetIndex + 1
                let readBytes = Bytes(data)
                
                do {
                    let decryptChunk = try weakSelf.crypto.decryptChunk(chunkData: readBytes, chunkNumber: chunkNumber, header: weakSelf.header)
                    let decryptChunkData = Data(decryptChunk)
                    decryptedFullData.append(decryptChunkData)
                    
                    let bytesToRespond = min(Int(firstChankOffset + requestedLength), decryptedFullData.count)
                    let range = Range(uncheckedBounds: (Int(firstChankOffset), bytesToRespond))
                    let dataToRespond = decryptedFullData.subdata(in: range)
                    

                    weakSelf.loadingRequest.dataRequest?.respond(with: dataToRespond)
                    
                    print("localFileReaderlocalFileReader",  dataRequest.currentOffset, dataRequest.requestedOffset, weakSelf.uuid)
                    
                                        
                    if off_t(decryptedFullData.count) - firstChankOffset >= dataRequest.requestedLength {
                        weakSelf.responseSucces(result: "")
                    }

                } catch {
                    print(error)
                }
                
                
                myChankIndex = myChankIndex + 1
            } error: { error in
                
                
                print("errorerrorerror", error)
                
            }

            
            
        }
        
        func fillContentInformation() {
            let filename: NSString = self.header.fileName! as NSString
            let pathExtention = filename.pathExtension
            self.loadingRequest.contentInformationRequest?.contentType = self.mimeTypeForPath(pathExtension: pathExtention)
//            self.loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            self.loadingRequest.contentInformationRequest?.contentLength = Int64(self.header.dataSize)
        }
        
        
        func loadDataTest(decryptDataBytesOr: Bytes) {
            
            let filename: NSString = self.header.fileName! as NSString
            let pathExtention = filename.pathExtension
            self.loadingRequest.contentInformationRequest?.contentType = self.mimeTypeForPath(pathExtension: pathExtention)
            self.loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            self.loadingRequest.contentInformationRequest?.contentLength = Int64(self.header.dataSize)
        
            guard let dataRequest = self.loadingRequest.dataRequest else {
                return
            }
            
            let headerOffset = off_t(self.crypto.startOffSet(header: self.header))
            let palyerCurrentOffset = self.dataRequestCurrentOffset
            let playerLength = self.dataRequestRequestedLength
            let chankSize = self.crypto.chunkSizeForHeader(header: self.header)
            
            guard let localFileReader = self.fileReader else {
                return
            }
            
            var playerFullData = Data()
            
            var index: Int = .zero
            
                  
            localFileReader.startRead { [weak self] data, startOffSet, fromOffset, length, finish in
                guard let weakSelf = self else {
                    return
                }
                
                if weakSelf.isExpired {
                    return
                }
                
                let offset = fromOffset - headerOffset
                var playerStartOffset =  palyerCurrentOffset - offset
                playerStartOffset = max(playerStartOffset, .zero)
  
                let bytes = Bytes(data)
                let fromOffSetIndex = UInt64((Double(offset) / Double(chankSize)))
                let chunkNumber = fromOffSetIndex + 1
                playerStartOffset = playerStartOffset + Int64(40 * fromOffSetIndex)
                
                playerStartOffset = index == .zero ? playerStartOffset : .zero

                do {
                    let decryptChunk = try weakSelf.crypto.decryptChunk(chunkData: bytes, chunkNumber: chunkNumber, header: weakSelf.header)
                    let playerBytes = decryptChunk.copyMemory(fromIndex: Int(playerStartOffset), toIndex: Int(decryptChunk.count))
                    let playerData = Data(playerBytes)
                    playerFullData.append(playerData)
                                                    
                    let dataToRespond = playerFullData.subdata(in: Range(uncheckedBounds: (.zero, min(Int(playerLength), playerFullData.count))))
                    let fff = dataToRespond.count >= Int64(dataRequest.requestedLength)
                    weakSelf.loadingRequest.dataRequest?.respond(with: dataToRespond)
                    if fff {
                        weakSelf.loadingRequest.finishLoading()
//                        weakSelf.responseSucces(result: "")
                    }
                    
                    index = index + 1
                    
                    print("localFileReader", weakSelf.uuid, fromOffSetIndex, playerStartOffset)
                    
                } catch {
                    print(error)
                }
                
                
                
            } error: { error in
                print(error)
            }

        }
        
        
        override func cancel() {
            
            super.cancel()
            
            guard let dataRequest = self.loadingRequest.dataRequest else {
                return
            }
            
            print("dataRequest cancel", "requestedOffset", dataRequest.requestedOffset, "requestedLength", dataRequest.requestedLength, "uuid =", self.uuid)
        }

    }
    
    
    
}

extension STAssetResourceLoader {
    
    class LocalFileReader {
        
        let url: URL
        let dataChunkSize: off_t
        let offset: off_t
        let length: off_t
        let queue: DispatchQueue
                
        lazy private var fileReader: STFileReader = {
            let result = STFileReader(fileURL: self.url)
            result.open()
            return result
        }()
        
        init(url: URL, dataChunkSize: off_t, offset: off_t, length: off_t, queue: DispatchQueue) {
            self.url = url
            self.dataChunkSize = dataChunkSize
            self.offset = offset
            self.queue = queue
            self.length = length
        }
        
        func startRead(handler: @escaping (_ chunk: Data, _ startOffset: off_t, _ fromOffset: off_t, _ length: off_t, _ finish: Bool) -> Void, error: @escaping (Error) -> Void) {
            self.read(offset: self.offset, handler: handler, error: error)
        }
        
        private func read(offset: off_t, handler: @escaping (_ chunk: Data, _ startOffset: off_t, _ fromOffset: off_t, _ length: off_t, _ finish: Bool) -> Void, error: @escaping (Error) -> Void) {
            
            let fullSize = Int64(self.fileReader.fullSize)
            let offset = min(offset, fullSize)
            
            let dataChunkSize = self.dataChunkSize
            guard dataChunkSize > .zero else {
                handler(Data(), self.offset, offset, self.dataChunkSize, true)
                return
            }
            let finish = offset + dataChunkSize >= self.length + self.offset || offset + dataChunkSize >= fullSize
            self.fileReader.read(fromOffset: offset, length: dataChunkSize, queue: self.queue) { [weak self] dispatchData in
                guard let weakSelf = self, let dispatchData = dispatchData else {
                    error(LoaderError.readError)
                    return
                }
                let data = Data(copying: dispatchData)
                handler(data, weakSelf.offset, offset, dataChunkSize, finish)
                if !finish {
                    let nextOffset = offset + weakSelf.dataChunkSize
                    weakSelf.queue.asyncAfter(deadline: .now() + 0.2) {
                        weakSelf.read(offset: nextOffset, handler: handler, error: error)
                    }
                    
                }
            }
        }
        
    }
    
}

extension STAssetResourceLoader {
    
    enum LoaderError: Error, IError {
        case readError
        
        
        var message: String {
            switch self {
            case .readError:
                return "error_unknown_error".localized
            }
        }
        
    }
    
    
    
}
