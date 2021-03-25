//
//  STDiskCache.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import UIKit

protocol IDiskCacheObject: AnyObject {
    var diskCacheCost: Int? { get }
}

extension STFileRetryerManager {
    
    class DiskCache<T: IDiskCacheObject> {
        
        private let storage = NSCache<NSString, T>()
        
        init(countLimit: Int = 400) {
            self.storage.countLimit = countLimit
        }
        
        func retryFile(source: IRetrySource, success: @escaping RetryerSuccess<T>, failure: @escaping RetryerFailure) {
            if let obj = self.object(for: source.identifier) {
                success(obj)
            } else {
                failure(RetryerError.fileNotFound)
            }
        }
        
        func didAddedMemry(source: IRetrySource) throws {
            guard let data = STApplication.shared.fileSystem.contents(in: source.fileSaveUrl) else {
                throw RetryerError.fileNotFound
            }
            let obj = try self.createObject(from: data, source: source)
            if let cost = obj.diskCacheCost {
                self.storage.setObject(obj, forKey: source.identifier as NSString, cost: cost)
            } else {
                self.storage.setObject(obj, forKey: source.identifier as NSString)
            }
            
        }
        
        func object(for identifier: String) -> T? {
            let result = self.storage.object(forKey: identifier as NSString)
            return self.storage.object(forKey: identifier as NSString)
        }
        
        func createObject(from data: Data, source: IRetrySource) throws -> T {
            fatalError("method not implemented")
        }
        
    }
    
    class DiskImageCache: DiskCache<UIImage> {
        
        private let storage = NSCache<NSString, UIImage>()
        
        override func createObject(from data: Data, source: IRetrySource) throws -> UIImage {
            let decryptData = try STApplication.shared.crypto.decryptData(data: data, header: source.header)
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

