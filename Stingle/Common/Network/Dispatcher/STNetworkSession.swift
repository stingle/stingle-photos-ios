//
//  STNetworkSession.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/3/21.
//

import Foundation
import Alamofire

class STNetworkSession: NSObject {
    
    fileprivate let rootQueue: DispatchQueue
    fileprivate let serializationQueue: DispatchQueue
    fileprivate var urlSession: URLSession!
    
    fileprivate var requests = [URLSessionTask: MultipartFormDataRequest]()
    
    init(rootQueue: DispatchQueue = DispatchQueue(label: "org.stingle.session.rootQueue"), serializationQueue: DispatchQueue? = nil, configuration: URLSessionConfiguration = .default) {
        self.rootQueue = rootQueue
        self.serializationQueue = serializationQueue ?? rootQueue
        super.init()
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
        
}

extension STNetworkSession {
    
    func upload(request: MultipartFormDataRequest) -> URLSessionUploadTask {
        let task = self.urlSession.uploadTask(withStreamedRequest: request.asURLRequest())
        self.rootQueue.async(flags: .barrier) { [weak self] in
            self?.requests[task] = request
            task.resume()
        }
        return task
    }
    
}

extension STNetworkSession: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        self.rootQueue.async(flags: .barrier) { [weak self] in
            
            let inputStream = self?.requests[task]?.inputStream
            
            self?.rootQueue.async {
//                inputStream?.open()
                completionHandler(inputStream)
            }
            
            
        }
                
        print("")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        let requests = self.requests[task]        
        
        print("totalBytesExpectedToSend", requests?.bodyBytesCount ?? .zero, totalBytesSent, bytesSent, task.progress.fractionCompleted)
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("")
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("")
    }
    
}

protocol IFormDataRequestBodyPart {
    func writeBodyStream(to outputStream: OutputStream, boundary: String) throws -> Int
}

class MultipartFormDataRequest {
    
    let boundary: String = UUID().uuidString
    private var bodyParts = [IFormDataRequestBodyPart]()
   
    let url: URL
    let headers: [String: String]?
    
    private(set) var bodyBytesCount: UInt = .zero
    private(set) var inputStream: InputStream?
    
    private(set) lazy var directoryURL: URL = {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let directoryURL = tempDirectoryURL.appendingPathComponent("files.uploading/multipart.form.data")
        return directoryURL
    }()
    
    private(set) lazy var fileURL: URL = {
        let fileName = self.boundary
        let fileURL = self.directoryURL.appendingPathComponent(fileName)
        return fileURL
    }()

    init(url: URL, headers: [String: String]?) {
        self.url = url
        self.headers = headers
    }
    
    func addTextField(named name: String, value: String) {
        let part = TextField(name: name, value: value)
        self.bodyParts.append(part)
    }
    
    func addDataField(named name: String, filename: String, data: Data, mimeType: String) {
        let part = DataField(name: name, filename: filename, mimeType: mimeType, data: data)
        self.bodyParts.append(part)
    }
    
    func addDataField(named name: String, filename: String, fileUrl: URL, mimeType: String) {
        let part = FileField(name: name, filename: filename, mimeType: mimeType, fileUrl: fileUrl)
        self.bodyParts.append(part)
    }
    
    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(self.boundary)", forHTTPHeaderField: "Content-Type")
        
        if let headers = self.headers {
            headers.forEach { header in
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        return request
    }
    
    func build() throws {
        
        let fileManager = FileManager.default
        
        let directoryURL = self.directoryURL
        let fileURL = self.fileURL
        
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                
        if let inputStream = self.inputStream {
            inputStream.close()
            try fileManager.removeItem(at: fileURL)
        }
        
        guard let outputStream = OutputStream(url: fileURL, append: false) else {
            throw STNetworkDispatcher.NetworkError.badRequest
        }
        outputStream.open()
        
        defer {
            outputStream.close()
        }
        
        var parts = self.bodyParts
        parts.append(EndField())
        
        for part in parts {
            do {
                let bytesCount = try part.writeBodyStream(to: outputStream, boundary: self.boundary)
                self.bodyBytesCount += UInt(bytesCount)
            } catch {
                throw STNetworkDispatcher.NetworkError.badRequest
            }
        }
        guard let inputStream = InputStream(url: fileURL) else {
            throw STNetworkDispatcher.NetworkError.badRequest
        }
        
        self.inputStream = inputStream
    }
    
    
}

extension MultipartFormDataRequest {
    
    struct TextField: IFormDataRequestBodyPart {
                
        let name: String
        let value: String
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String) throws -> Int {
            var fieldString = "--\(boundary)\r\n"
            fieldString += "Content-Disposition: form-data; name=\"\(self.name)\"\r\n"
            fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
            fieldString += "Content-Transfer-Encoding: 8bit\r\n"
            fieldString += "\r\n"
            fieldString += "\(self.value)\r\n"
            
            let data = Data(fieldString.utf8)
            var buffer = [UInt8](repeating: 0, count: data.count)
            data.copyBytes(to: &buffer, count: data.count)
            return outputStream.write(buffer, maxLength: data.count)
        }
        
    }
    
    struct DataField: IFormDataRequestBodyPart {
        let name: String
        let filename: String
        let mimeType: String
        let data: Data
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String) throws -> Int {
            
            var fieldData = Data()
            fieldData.append("--\(boundary)\r\n")
                        
            
            fieldData.append("Content-Disposition: form-data; name=\"\(self.name); filename=\"\(self.filename)\"\r\n")
            fieldData.append("Content-Type: \(self.mimeType)\r\n")
            fieldData.append("\r\n")
            fieldData.append(self.data)
            fieldData.append("\r\n")
            
            var buffer = [UInt8](repeating: 0, count: data.count)
            data.copyBytes(to: &buffer, count: data.count)
            return outputStream.write(buffer, maxLength: data.count)
            
        }
    }
    
    struct FileField: IFormDataRequestBodyPart {
        
        let name: String
        let filename: String
        let mimeType: String
        let fileUrl: URL
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String) throws -> Int {
            
            guard let inputStream = InputStream(url: self.fileUrl) else {
                throw STNetworkDispatcher.NetworkError.badRequest
            }
            
            var fieldData = Data()
            fieldData.append("--\(boundary)\r\n")
            
            fieldData.append("Content-Disposition: form-data; name=\"\(self.name)\"; filename=\"\(self.filename)\r\n")
            
            fieldData.append("Content-Type: \(self.mimeType)\r\n")
            fieldData.append("\r\n")
            
            var resultBytes: Int = .zero
        
            var buffer = [UInt8](repeating: 0, count: fieldData.count)
            fieldData.copyBytes(to: &buffer, count: fieldData.count)
            resultBytes += outputStream.write(buffer, maxLength: fieldData.count)
            
            inputStream.open()
            defer { inputStream.close() }
            
            let streamBufferSize = 1024
            
            while inputStream.hasBytesAvailable {
                
                var buffer = [UInt8](repeating: 0, count: streamBufferSize)
                let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)

                if let streamError = inputStream.streamError {
                    throw AFError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: streamError))
                }

                if bytesRead > 0 {
                    if buffer.count != bytesRead {
                        buffer = Array(buffer[0..<bytesRead])
                    }
                    let write = outputStream.write(buffer, maxLength: buffer.count)
                    resultBytes += write
                    
                } else {
                    break
                }
            }
            
            var end = Data()
            end.append("\r\n")
            
            var bufferEnd = [UInt8](repeating: 0, count: end.count)
            end.copyBytes(to: &bufferEnd, count: end.count)
            resultBytes += outputStream.write(bufferEnd, maxLength: end.count)
            
            return resultBytes
                                
        }
        
    }
    
    struct EndField: IFormDataRequestBodyPart {
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String) throws -> Int {
            var data = Data()
            let fieldData = "\r\n--\(boundary)--\r\n"
            data.append(fieldData)
            
            var buffer = [UInt8](repeating: 0, count: data.count)
            data.copyBytes(to: &buffer, count: data.count)
            return outputStream.write(buffer, maxLength: data.count)
            
        }
        
    }
    
    
}

fileprivate extension Data {
    
    mutating func append(_ string: String) {
        let data = Data(string.utf8)
        self.append(data)
    }
    
}
