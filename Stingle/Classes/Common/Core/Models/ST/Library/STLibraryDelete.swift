//
//  STLibraryDelete.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/7/21.
//

import Foundation

extension STLibrary {
            
    class DeleteFile: Codable {
        
        private enum CodingKeys: String, CodingKey {
            case fileName = "file"
            case type = "type"
            case date = "date"
        }
        
        var fileName: String
        var type: Int
        var date: String
      
    }
    
}
