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
        
        override func responseSucces(result: Data) {
            self.loadingRequest.finishLoading()
            super.responseSucces(result: result)
        }
        
        override func responseFailed(error: IError) {
            guard !self.isExpired else {
                super.responseFailed(error: error)
                return
            }
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
        var data: Data?
        
        init(loadingRequest: AVAssetResourceLoadingRequest, decrypter: Decrypter, header: STHeader) {
            self.decrypter = decrypter
            super.init(loadingRequest: loadingRequest, header: header)
        }
        
        override func cancel() {
            super.cancel()
        }
                
        override func loadData() {
            super.loadData()
            guard let dataRequest = self.loadingRequest.dataRequest else {
                return
            }
            let requestedOffset = UInt64(dataRequest.requestedOffset)
            let requestedLength = UInt64(dataRequest.requestedLength)
                        
            self.decrypter.startDecrypter(requestedOffset: requestedOffset, requestedLength: requestedLength) { [weak self] data, finished in
                guard let weakSelf = self, !weakSelf.isExpired else {
                    return true
                }
                weakSelf.data = data
                let isFinish = data.count >= dataRequest.requestedLength || finished
                weakSelf.updateResponse()
                if isFinish  {
                    weakSelf.responseSucces(result: data)
                }
               
                return isFinish
                
            } error: { [weak self] error in
                self?.responseFailed(error: LoaderError.error(error: error))
            }
        }
        
        func updateResponse() {
            guard let dataRequest = self.loadingRequest.dataRequest, let data = self.data else {
                return
            }
            let end = min(data.count, dataRequest.requestedLength)
            let start = dataRequest.currentOffset - dataRequest.requestedOffset
            guard end > start else {
                return
            }
            let range = Range(uncheckedBounds: (Int(start), Int(end)))
            let requestedDataChank = data.subdata(in: range)
            dataRequest.respond(with: requestedDataChank)
        }
        
    }
    
    
}
