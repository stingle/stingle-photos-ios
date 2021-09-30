//
//  STAlbumsSharedVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/26/21.
//

import Foundation

class STAlbumsSharedVM {
    
    private let syncManager = STApplication.shared.syncManager

    func sync() {
        self.syncManager.sync()
    }
    
}
