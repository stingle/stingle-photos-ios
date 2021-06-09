//
//  STAVAssetResourceLoader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import AVKit

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
    private let dispatchQueue = DispatchQueue(label: "Player.Queue", attributes: .concurrent)
    private let operationManager = STOperationManager.shared
    
    lazy private var operationQueue: STOperationQueue = {
        let queue = self.operationManager.createQueue(maxConcurrentOperationCount: 1, underlyingQueue: self.dispatchQueue)
        return queue
    }()
    
    lazy private var decrypter: Decrypter = {
        let fileReader = LocalFileReader(url: self.url, queue: self.dispatchQueue)
        let decrypter = Decrypter(header: self.header, reader: fileReader)
        return decrypter!
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
        let operation = FileOperation(loadingRequest: loadingRequest, decrypter: self.decrypter, header: self.header)
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
    
    enum LoaderError: Error, IError {
        case readError
        case error(error: Error)
        
        var message: String {
            switch self {
            case .readError:
                return "error_unknown_error".localized
            case .error(let error):
                if let iRrror = error as? IError {
                    return iRrror.message
                }
                return error.localizedDescription
            }
        }
        
    }
    
}
