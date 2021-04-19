//
//  STAlbumsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation

class STAlbumsVM {
    
    private let syncManager = STApplication.shared.syncManager

    func sync() {
        self.syncManager.sync()
    }
        
}
