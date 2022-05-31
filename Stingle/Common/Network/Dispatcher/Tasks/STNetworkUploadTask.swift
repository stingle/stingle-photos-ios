//
//  STNetworkUploadTask.swift
//  Stingle
//
//  Created by Khoren Asatryan on 2/13/22.
//

import UIKit

protocol IFormDataRequestBodyPart {
    
    var description: String { get }
    func culculateFullData(boundary: String) -> Int64
    func writeBodyStream(to outputStream: OutputStream, boundary: String, progressHandler: STNetworkUploadTask.Request.ProgressHandler<Int64>) throws
}

class STNetworkUploadTask: STNetworkTask<URLSessionUploadTask, STNetworkUploadTask.Request> {
    
    private let progressTask = Progress()
    private var receiveData: Data?
    private var lastResponseDate: Date?
    
    override func resumeTask() {
        super.resumeTask()
        guard !self.request.isBuilded else {
            return
        }
                
        self.queue.async(flags: .barrier) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            do {
                try weakSelf.request.build { [weak weakSelf] progress, stop in
                    stop = weakSelf?.isCanceled ?? true
                }
                let task = weakSelf.session.uploadTask(with: weakSelf.request.asURLRequest(), fromFile: weakSelf.request.fileURL)
                task.earliestBeginDate = Date()
                weakSelf.urlTask = task
                task.resume()
            } catch {
                weakSelf.completion(with: .failure(error: .error(error: error)))
            }
            
        }
    }
    
    override func clean() {
        super.clean()
        self.request.clean()
    }
    
    override func didSendBodyData(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        super.didSendBodyData(bytesSent: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        self.progressTask.totalUnitCount = self.request.totalUnitCount
        self.progressTask.completedUnitCount = totalBytesSent
        self.progress?(self.progressTask)
    }
    
    override func didCompleteWithError(error: Error?) {
        super.didCompleteWithError(error: error)
        if let error = error {
            self.completion(with: .failure(error: STNetworkDispatcher.NetworkError.error(error: error)))
        } else {
            self.completion(with: .success(result: self.receiveData ?? Data()))
        }
    }
    
    override func didReceive(data: Data) {
        super.didReceive(data: data)
        self.receiveData = data
    }
    
    //MARK: - Private methods
    
    private func didBuildProgress(progress: Double) {
        let total: Double = 10000
        let carrent = total * progress
        let pp = Progress()
        
        pp.totalUnitCount = Int64(total)
        pp.completedUnitCount = Int64(carrent)
        
        guard let date = self.lastResponseDate else {
            self.progress?(pp)
            self.lastResponseDate = Date()
            return
        }
        
        let currentDate = Date()
        let diff = currentDate.timeIntervalSince(date)
        if diff >= 1 {
            self.progress?(pp)
            self.lastResponseDate = currentDate
        }
    }
    
    private func didBuildRequest() {
        guard !self.isCanceled else {
            return
        }
        let task = self.session.uploadTask(with: self.request.asURLRequest(), fromFile: self.request.fileURL)
        self.urlTask = task
        task.resume()
    }
    
}

extension STNetworkUploadTask: StreamDelegate {
    
}

extension STNetworkUploadTask {
    
    class Request: INetworkTaskRequest {
        
        typealias ProgressHandler<T> = ((_ progress: T, _ stop: inout Bool) -> Void)
        
        let boundary: String = UUID().uuidString
        private var bodyParts = [IFormDataRequestBodyPart]()
       
        let url: URL
        let headers: [String: String]?
        
        private(set) var isBuilded: Bool = false
        
        private(set) var bodyBytesCount: UInt = .zero
        
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
        
        private(set) lazy var totalUnitCount: Int64 = {
            var fullDataSize = Int64.zero
            self.bodyParts.forEach { fullDataSize = fullDataSize + $0.culculateFullData(boundary: self.boundary) }
            return fullDataSize
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
        
        fileprivate func build(progressHandler: ProgressHandler<Double>) throws {
            
            guard !self.isBuilded else {
                throw STNetworkDispatcher.NetworkError.badRequest
            }
            
            let fullDataSize = self.totalUnitCount
            
            let freeDiskUnits = STFileSystem.DiskStatus.freeDiskSpaceUnits
            let afterImportfreeDiskUnits = STBytesUnits(bytes: freeDiskUnits.bytes - fullDataSize)
            
            guard afterImportfreeDiskUnits > STConstants.minFreeDiskUnits else {
                throw STFileUploader.UploaderError.memoryLow
            }
            
            self.isBuilded = true
                        
            let fileManager = FileManager.default
            
            let directoryURL = self.directoryURL
            let fileURL = self.fileURL
            
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            guard let outputStream = OutputStream(url: fileURL, append: false) else {
                throw STNetworkDispatcher.NetworkError.badRequest
            }
            outputStream.open()
            
            defer {
                outputStream.close()
            }
            
            var parts = self.bodyParts
            parts.append(EndField())
                        
            var writedCount = Int64.zero
            
            for part in parts {
                var currentWritedCount = Int64.zero
                do {
                    try part.writeBodyStream(to: outputStream, boundary: self.boundary, progressHandler: { writed, stop in
                        currentWritedCount = writed
                        let processWrited = writedCount + writed
                        let process = Double(processWrited) / Double(fullDataSize)
                        progressHandler(process, &stop)
                    })
                    writedCount = writedCount + currentWritedCount
                } catch {
                    throw STNetworkDispatcher.NetworkError.badRequest
                }
            }
        }
        
        fileprivate func clean() {
            do {
                try FileManager.default.removeItem(at: self.fileURL)
            } catch {
                STLogger.log(error: error)
            }
        }
        
    }
    
}


extension STNetworkUploadTask.Request {
    
    struct TextField: IFormDataRequestBodyPart {
                
        let name: String
        let value: String
        
        var description: String {
            return self.name
        }
        
        func culculateFullData(boundary: String) -> Int64 {
            var fieldString = "--\(boundary)\r\n"
            fieldString += "Content-Disposition: form-data; name=\"\(self.name)\"\r\n"
            fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
            fieldString += "Content-Transfer-Encoding: 8bit\r\n"
            fieldString += "\r\n"
            fieldString += "\(self.value)"
            fieldString += "\r\n"
            let data = Data(fieldString.utf8)
            return Int64(data.count)
        }
    
        func writeBodyStream(to outputStream: OutputStream, boundary: String, progressHandler: ProgressHandler<Int64>) throws {
            var fieldString = "--\(boundary)\r\n"
            fieldString += "Content-Disposition: form-data; name=\"\(self.name)\"\r\n"
            fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
            fieldString += "Content-Transfer-Encoding: 8bit\r\n"
            fieldString += "\r\n"
            fieldString += "\(self.value)"
            fieldString += "\r\n"
            
            let data = Data(fieldString.utf8)
            let buffer = [UInt8](data)
            let count = outputStream.write(buffer, maxLength: buffer.count)
            var stop = false
            progressHandler(Int64(count), &stop)
            guard stop else {
                return
            }
            throw STNetworkDispatcher.NetworkError.cancelled
        }
        
    }
    
    struct DataField: IFormDataRequestBodyPart {

        let name: String
        let filename: String
        let mimeType: String
        let data: Data
        
        var description: String {
            return self.name
        }
        
        func culculateFullData(boundary: String) -> Int64 {
            var fieldData = Data()
            fieldData.append("--\(boundary)\r\n")
            fieldData.append("Content-Disposition: form-data; name=\"\(self.name); filename=\"\(self.filename)\"\r\n")
            fieldData.append("Content-Type: \(self.mimeType)\r\n")
            fieldData.append("\r\n")
            fieldData.append(self.data)
            fieldData.append("\r\n")
            
            return Int64(fieldData.count)
        }
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String, progressHandler: ProgressHandler<Int64>) throws {
            var fieldData = Data()
            fieldData.append("--\(boundary)\r\n")
            fieldData.append("Content-Disposition: form-data; name=\"\(self.name); filename=\"\(self.filename)\"\r\n")
            fieldData.append("Content-Type: \(self.mimeType)\r\n")
            fieldData.append("\r\n")
            fieldData.append(self.data)
            fieldData.append("\r\n")
            
            let buffer = [UInt8](fieldData)
            let count = outputStream.write(buffer, maxLength: buffer.count)
            var stop = false
            progressHandler(Int64(count), &stop)
            guard stop else {
                return
            }
            throw STNetworkDispatcher.NetworkError.cancelled
        }
    }
    
    struct FileField: IFormDataRequestBodyPart {
        
        let name: String
        let filename: String
        let mimeType: String
        let fileUrl: URL
        
        var description: String {
            return self.name
        }
        
        func culculateFullData(boundary: String) -> Int64 {
            var fieldData = Data()
            fieldData.append("--\(boundary)\r\n")
            fieldData.append("Content-Disposition: form-data; name=\"\(self.name)\"; filename=\"\(self.filename)\r\n")
            fieldData.append("Content-Type: \(self.mimeType)\r\n")
            fieldData.append("\r\n")
            fieldData.append("\r\n")
            
            var fullDataCount = Int64.zero
            fullDataCount = fullDataCount + Int64(fieldData.count)
            
            let fileInfo = try? FileManager.default.attributesOfItem(atPath: self.fileUrl.path)
            fullDataCount = fullDataCount + (fileInfo?[.size] as? Int64 ?? .zero)
            return Int64(fullDataCount)
        }
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String, progressHandler: ProgressHandler<Int64>) throws {
            
            guard let inputStream = InputStream(url: self.fileUrl) else {
                throw STNetworkDispatcher.NetworkError.badRequest
            }
            
            var writeCount: Int64 = .zero
            var stop = false
            
            var fieldData = Data()
            fieldData.append("--\(boundary)\r\n")
            fieldData.append("Content-Disposition: form-data; name=\"\(self.name)\"; filename=\"\(self.filename)\r\n")
            fieldData.append("Content-Type: \(self.mimeType)\r\n")
            fieldData.append("\r\n")
            
            let buffer = [UInt8](fieldData)
            var count = outputStream.write(buffer, maxLength: buffer.count)
            
            writeCount = writeCount + Int64(count)
            progressHandler(writeCount, &stop)
            guard !stop else {
                throw STNetworkDispatcher.NetworkError.cancelled
            }
            
            inputStream.open()
            defer { inputStream.close() }
            
            let streamBufferSize = 1024 * 1024
            var inputBuffer = [UInt8](repeating: 0, count: streamBufferSize)
            
            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&inputBuffer, maxLength: streamBufferSize)
                if let streamError = inputStream.streamError {
                    throw STNetworkDispatcher.NetworkError.error(error: streamError)
                }
                if bytesRead > 0 {
                    let currentWriteCount = outputStream.write(inputBuffer, maxLength: bytesRead)
                    writeCount = writeCount + Int64(currentWriteCount)
                    progressHandler(writeCount, &stop)
                    guard !stop else {
                        throw STNetworkDispatcher.NetworkError.cancelled
                    }
                    
                } else {
                    break
                }
            }
                     
            var end = Data()
            end.append("\r\n")
            let bufferEnd = [UInt8](end)
            count = outputStream.write(bufferEnd, maxLength: end.count)
            writeCount = writeCount + Int64(count)
            progressHandler(writeCount, &stop)
            
            guard stop else {
                return
            }
            throw STNetworkDispatcher.NetworkError.cancelled
            
        }
        
    }
    
    struct EndField: IFormDataRequestBodyPart {
        
        var description: String {
            return "EndField"
        }
        
        func culculateFullData(boundary: String) -> Int64 {
            var data = Data()
            let fieldData = "--\(boundary)--\r\n"
            data.append(fieldData)
            return Int64(data.count)
        }
        
        func writeBodyStream(to outputStream: OutputStream, boundary: String, progressHandler: ProgressHandler<Int64>) throws {
            var data = Data()
            let fieldData = "--\(boundary)--\r\n"
            data.append(fieldData)
            
            let buffer = [UInt8](data)
            let writeCount = outputStream.write(buffer, maxLength: data.count)
            var stop = false
            progressHandler(Int64(writeCount), &stop)
            guard stop else {
                return
            }
            throw STNetworkDispatcher.NetworkError.cancelled
        }
        
    }
    
    
    
}

fileprivate extension Data {
    
    mutating func append(_ string: String) {
        let data = Data(string.utf8)
        self.append(data)
    }
    
}
