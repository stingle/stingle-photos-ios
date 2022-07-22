//
//  STAssetResourceLoader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 10/1/21.
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
    
    let asset: AVURLAsset
    let url: URL
    
    private let cachingScheme = "STAssetScheme"
    private let scheme: Scheme
    private let header: STHeader
    private let dispatchQueue = DispatchQueue(label: "Player.Queue", attributes: .concurrent)
    private let file: ILibraryFile
    private var decrypters = [Decrypter]()
    
    lazy var networkSession: STNetworkSession = {
        let config = STNetworkSession.avStreamingConfiguration
        let networkSession = STNetworkSession(rootQueue: self.dispatchQueue, configuration: config)
        return networkSession
    }()
    
    init(file: ILibraryFile, header: STHeader) {
        guard let url = file.fileOreginalUrl,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
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
        self.file = file
        super.init()
        self.asset.resourceLoader.setDelegate(self, queue: self.dispatchQueue)
    }
    
    //MARK: - Private methods
    
    private func createResourceReader() -> IAssetResourceLoader {
        if STApplication.shared.fileSystem.fileExists(atPath: self.url.path) {
            let fileReader = LocaleReader(url: self.url, queue: self.dispatchQueue)
            return fileReader
        } else {
            let fileReader = NetworkReader(filename: self.file.file, dbSet: self.file.dbSet, queue: self.dispatchQueue, networkSession: self.networkSession)
            return fileReader
        }
    }
    
    private func createDecrypter(for request: AVAssetResourceLoadingRequest) -> Decrypter {
        let resourceReader = self.createResourceReader()
        let decrypter = Decrypter(header: self.header, reader: resourceReader, request: request)
        decrypter.delegate = self
        return decrypter
    }
    
    private func decrypter(for request: AVAssetResourceLoadingRequest) -> Decrypter? {
        return self.decrypters.first(where: { $0.request == request })
    }
    
}

extension STAssetResourceLoader: AVAssetResourceLoaderDelegate {
   
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if self.decrypter(for: loadingRequest) == nil {
            let decrypter = self.createDecrypter(for: loadingRequest)
            self.decrypters.append(decrypter)
            decrypter.start()
        }
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        if let decrypteIdex = self.decrypters.firstIndex(where: { $0.request == loadingRequest }) {
            self.decrypters[decrypteIdex].cancel()
            self.decrypters.remove(at: decrypteIdex)
        }
        
    }
    
}

extension STAssetResourceLoader: STAssetResourceLoaderDecrypterDelegate {
    
    func decrypter(didFinished decrypter: Decrypter) {
        self.dispatchQueue.async(flags: .barrier) { [weak self] in
            if let decrypteIdex = self?.decrypters.firstIndex(where: { $0.request == decrypter.request }) {
                self?.decrypters.remove(at: decrypteIdex)
            }
        }
    }
    
    
}

extension STAssetResourceLoader {
    
    
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
