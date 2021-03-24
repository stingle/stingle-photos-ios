//
//  STDiskCache.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/24/21.
//

import UIKit

extension STFileRetryer {
    
    class DiskCache {
        
        private let storage = NSCache<NSString, UIImage>()
        
        init() {
            self.storage.countLimit = 400
        }
        
        func retryFile(source: IRetrySource, success: @escaping RetryerSuccess<UIImage>, failure: @escaping RetryerFailure) {
            if let image = self.storage.object(forKey: source.identifier as NSString) {
                success(image)
            } else {
                failure(RetryerError.fileNotFound)
            }
        }
        
        func didAddedMemry(source: IRetrySource) throws {
            guard let data = STApplication.shared.fileSystem.contents(in: source.fileSaveUrl) else {
                throw RetryerError.fileNotFound
            }
            
//            source.header
            
            let decryptData = try STApplication.shared.crypto.decryptData(data: data, header: nil)
            guard let image = UIImage(data: decryptData) else {
                throw RetryerError.invalidData
            }
            self.storage.setObject(image, forKey: source.identifier as NSString, cost: image.cost)
        }
        
        func image(for identifier: String) -> UIImage? {
            return self.storage.object(forKey: identifier as NSString)
        }

    }
        
}

extension UIImage {
    
    var cost: Int {
        let pixel = Int(size.width * size.height * scale * scale)
        guard let cgImage = cgImage else {
            return pixel * 4
        }
        return pixel * cgImage.bitsPerPixel / 8
    }

    
}

