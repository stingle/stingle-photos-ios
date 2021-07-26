//
//  STAccountVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/27/21.
//

import Foundation

class STAccountVM {
    
    func getUser() -> STUser? {
        return STApplication.shared.user()
    }
    
}
