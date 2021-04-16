//
//  STAlbumsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation

class STAlbumsVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let uploader = STApplication.shared.uploader
    
    

    func sync() {
        self.syncManager.sync()
    }
        
}


extension STAlbumsVC {
    
    struct ViewItem {
        let image: STImageView.Image?
        let title: String?
        let subTille: String?
    }
    
}
