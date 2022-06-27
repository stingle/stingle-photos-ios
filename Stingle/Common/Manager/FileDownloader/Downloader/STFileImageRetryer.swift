//
//  STFileImageRetryer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/13/21.
//

import UIKit

protocol IFileRetrySource: IDownloaderSource {
    var version: String { get }
    var header: STHeader { get }
    var folderType: STFileSystem.FolderType { get }
}

extension IFileRetrySource {
    
    var identifier: String {
        return "\(self.version)_\(self.folderType.stringValue)_\(self.fileName)"
    }
    
    var fileDownloadTmpUrl: URL? {
        return self.fileTmpUrl
    }
    
    var fileTmpUrl: URL {
        return self.fileSaveUrl
    }
    
    var fileSaveUrl: URL {
        guard let url = STApplication.shared.fileSystem.url(for: self.folderType, filePath: self.fileName) else {
            fatalError("cacheURL not found")
        }
        return url
    }
    
}

extension STDownloaderManager {
        
    class ImageRetryer: Downloader<UIImage> {
        
        private let diskCache = DiskImageCache()
        private let memoryCache = MemoryCache()
        
        override func createOperation(for source: IDownloaderSource) -> Operation {
            
            guard ((source as? IFileRetrySource) != nil) else {
                fatalError("use IFileRetrySource")
            }
            
            let operation = DownloaderOperation(request: source, memoryCache: self.memoryCache, diskCache: self.diskCache) { (obj) in
            } progress: { (progress) in
            } failure: { (error) in
            }
            return operation
        }

        func isFileExists(source: IDownloaderSource) -> Bool {
            return self.memoryCache.isFileExists(source: source)
        }
        
    }
        
    class DiskImageCache: DiskCache<UIImage> {
                
        override func createObject(from data: Data, source: IDownloaderSource) throws -> UIImage {
            guard let source = source as? IFileRetrySource else {
                throw RetryerError.invalidData
            }
                                    
            let decryptData = try STApplication.shared.crypto.decryptData(data: data, header: source.header)
            if source.header.fileName?.pathExtension.lowercased() == "gif", let image = UIImage.gif(data: decryptData) {
                return image
            }
            
            guard let image = UIImage(data: decryptData) else {
                throw RetryerError.invalidData
            }
            return image
        }

    }
        
}

extension UIImage: IDiskCacheObject {

    var diskCacheCost: Int? {
        let pixel = Int(self.size.width * self.size.height * self.scale * self.scale)
        guard let cgImage = self.cgImage else {
            return pixel * 4
        }
        return pixel * cgImage.bitsPerPixel / 8
    }
    
}
