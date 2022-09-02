//
//  STSyncResponse.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/5/21.
//

import Foundation

public class STLibrary {
      
}

extension STLibrary {
    
    public enum DBSet: Int {
        case none = -1
        case galery = 0
        case trash = 1
        case album = 2
    }
    
    public enum LibraryError: IError {
        case parsError
        
        public var message: String {
            switch self {
            case .parsError:
                return "error_unknown_error".localized
            }
        }
    }
    
}


