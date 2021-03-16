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
    
    enum LibraryError: IError {
        case parsError
        
        var message: String {
            switch self {
            case .parsError:
                return "nework_error_unknown_error".localized
            }
        }
    }
    
}


