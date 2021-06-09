//
//  STFileWriteer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/5/21.
//

import Foundation

final class STFileHandle {
   
    let fileURL: URL
    
    let fileHandle: FileHandle?
        
    lazy var fullSize: Int = {
        let size = STApplication.shared.fileSystem.contents(in: self.fileURL)?.count ?? 0
        return size
    }()
    
    init(writing fileURL: URL) {
        self.fileURL = fileURL
        self.fileHandle = FileHandle(forWritingAtPath: fileURL.path)
    }
    
    init(read fileURL: URL) {
        self.fileURL = fileURL
        self.fileHandle = FileHandle(forReadingAtPath: fileURL.path)
    }

    // MARK: Managing I/O
    
    func close() {
        try? self.fileHandle?.close()
    }
    
    func write(offset: off_t, data: Data) throws {
        try self.fileHandle?.seek(toOffset: UInt64(offset))
        self.fileHandle?.write(data)
    }
    
    func read(offset: off_t, length: UInt64) throws  -> Data {
        try self.fileHandle?.seek(toOffset: UInt64(offset))
        guard let data = self.fileHandle?.readData(ofLength: Int(length)) else {
            throw FileHandleError.dataNotFound
        }
        return data
    }
    
    deinit {
        self.close()
    }
}


extension STFileHandle {
    
    enum FileHandleError: IError {
        case dataNotFound
        
        var message: String {
            switch self {
            case .dataNotFound:
                return "nework_error_data_not_found".localized
        
            }
        }
    }
  
}
