//
//  IAssetResourceNetworkFileReader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/9/21.
//

import Foundation


extension STAssetResourceLoader {
    
    class NetworkFileReader {
        
        let url: URL
        let queue: DispatchQueue
        
        init(url: URL, queue: DispatchQueue) {
            self.url = url
            self.queue = queue
        }
                
        
    }
    
    
}

extension STAssetResourceLoader.NetworkFileReader: IAssetResourceReader {
    
    
    func startRead(startOffset: UInt64, dataChunkSize: UInt64, handler: @escaping (_ chunk: Data, _ fromOffset: UInt64, _ finish: Bool) -> Bool, error: @escaping (Error) -> Void) {
        
        
        
    }
   
}
