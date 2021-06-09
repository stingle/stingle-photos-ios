//
//  STAVAssetResourceLocalFileOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/7/21.
//

import AVKit
import MobileCoreServices
import Sodium

extension STAssetResourceLoader {
    
    class Operation: STOperation<Data> {
        
        let loadingRequest: AVAssetResourceLoadingRequest
        let crypto = STApplication.shared.crypto
        let header: STHeader
        
        init(loadingRequest: AVAssetResourceLoadingRequest, header: STHeader) {
            self.loadingRequest = loadingRequest
            self.header = header
            super.init(success: nil, failure: nil)
        }
        
        // MARK: - override
        
        override func resume() {
            super.resume()
            self.loadData()
        }
        
        override func cancel() {
            super.cancel()
            self.finish()
        }
        
        override func responseSucces(result: Any) {
            self.loadingRequest.finishLoading()
            super.responseSucces(result: result)
        }
        
        override func responseFailed(error: IError) {
            self.loadingRequest.finishLoading(with: error)
            super.responseFailed(error: error)
        }
        
        // MARK: - Public override
        
        func loadData() {
            self.fillContentInformation()
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
        
        func fillContentInformation() {
            let filename: NSString = self.header.fileName! as NSString
            let pathExtention = filename.pathExtension
            self.loadingRequest.contentInformationRequest?.contentType = self.mimeTypeForPath(pathExtension: pathExtention)
            self.loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            self.loadingRequest.contentInformationRequest?.contentLength = Int64(self.header.dataSize)
        }
  
    }
        
}

extension STAssetResourceLoader {
    
    class FileOperation: Operation {
        
        let decrypter: Decrypter
        
        init(loadingRequest: AVAssetResourceLoadingRequest, decrypter: Decrypter, header: STHeader) {
            self.decrypter = decrypter
            super.init(loadingRequest: loadingRequest, header: header)
        }
        
        var isEnd = false
        
        override func loadData() {
            super.loadData()
            
            guard let dataRequest = self.loadingRequest.dataRequest else {
                return
            }
            let requestedOffset = UInt64(dataRequest.requestedOffset)
            
                        
            self.decrypter.startDecrypter(requestedOffset: requestedOffset) { [weak self] data, finished in
                guard let weakSelf = self, !weakSelf.isExpired, !weakSelf.isEnd else {
                    return true
                }
                let isFinish = data.count >= dataRequest.requestedLength || finished
                let end = min(data.count, dataRequest.requestedLength)
                let start = dataRequest.currentOffset - dataRequest.requestedOffset
                let range = Range(uncheckedBounds: (Int(start), Int(end)))
                let requestedDataChank = data.subdata(in: range)
                weakSelf.loadingRequest.dataRequest?.respond(with: requestedDataChank)
                if isFinish  {
                    weakSelf.responseSucces(result: data)
                    weakSelf.isEnd = isFinish
                }
               
                return isFinish
                
            } error: { [weak self] error in
                self?.responseFailed(error: LoaderError.error(error: error))
            }
            
        }
        
    }
    
}
