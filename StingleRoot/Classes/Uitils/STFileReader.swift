//
//  STFileReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/25/21.
//

import Foundation

public final class STFileReader {
   
    let fileURL: URL
    private var channel: DispatchIO?
        
    lazy var fullSize: Int = {
        let size = STApplication.shared.fileSystem.contents(in: self.fileURL)?.count ?? 0
        return size
    }()
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    // MARK: Managing I/O
    
    @discardableResult
    func open() -> Bool {
        guard self.channel == nil else {
            return true
        }
        guard let path = (self.fileURL.path as NSString).utf8String else { return false }
        self.channel = DispatchIO(type: .random, path: path, oflag: 0, mode: 0, queue: .main, cleanupHandler: { error in
            STLogger.log(info: "Closed a channel with status: \(error)")
        })
        self.channel?.setLimit(lowWater: .max)
        return true
    }
    
    func close() {
        self.channel?.close()
        self.channel = nil
    }
    
    // MARK: Reading the File
    
    func read(byteRange: CountableRange<off_t>, queue: DispatchQueue = .main, completionHandler: @escaping (DispatchData?) -> Void) {
        if let channel = self.channel {
            channel.read(offset: off_t(byteRange.startIndex), length: byteRange.count, queue: queue, ioHandler: { done, data, error in
                completionHandler(data)
            })
        }
        else {
            completionHandler(nil)
        }
    }
    

    func read(fromOffset: off_t, length: off_t, queue: DispatchQueue = .main, completionHandler: @escaping (DispatchData?) -> Void) {
        if let channel = self.channel {
            channel.read(offset: fromOffset, length: Int(length), queue: queue, ioHandler: { done, data, error in
                completionHandler(data)
            })
        }
        else {
            completionHandler(nil)
        }
    }
    
    deinit {
        self.close()
    }
}
