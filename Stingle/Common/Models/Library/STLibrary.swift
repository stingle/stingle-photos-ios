//
//  STSyncResponse.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/5/21.
//

import Foundation

class STLibrary {
      
}

extension STLibrary {
    
    enum DBSet: Int {
        case file = 0
        case trash = 1
        case album = 2
    }
    
    enum LibraryError: IError {
        case parsError
        
        var message: String {
            switch self {
            case .parsError:
                return "error_unknown_error".localized
            }
        }
    }
    
}


