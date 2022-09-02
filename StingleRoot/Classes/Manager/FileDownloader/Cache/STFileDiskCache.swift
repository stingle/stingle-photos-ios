//
//  STDiskCache.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import UIKit

public protocol IDiskCacheObject: AnyObject {
    var diskCacheCost: Int? { get }
}

extension IDiskCacheObject {
    public var diskCacheCost: Int? {
        return nil
    }
}

public extension STDownloaderManager {
    
    class DiskCache<T: IDiskCacheObject> {
        
        private let storage = NSCache<NSString, T>()
        
        init(countLimit: Int = 400, totalCostLimit: Int = (10 * 1024 * 1024)) {
            self.storage.countLimit = countLimit
        }
        
        func retryFile(source: IDownloaderSource, success: @escaping RetryerSuccess<T>, failure: @escaping RetryerFailure) {
            if let obj = self.object(for: source.identifier) {
                success(obj)
            } else {
                failure(RetryerError.fileNotFound)
            }
        }
        
        func didAddedMemry(source: IDownloaderSource) throws {
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
            return result
        }
        
        func createObject(from data: Data, source: IDownloaderSource) throws -> T {
            fatalError("method not implemented")
        }
        
    }
            
}
