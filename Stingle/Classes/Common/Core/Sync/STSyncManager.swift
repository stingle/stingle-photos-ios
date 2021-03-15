//
//  STSyncManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

class STSyncManager {
    
    let sync: STSync
    
    let dataBase = STApplication.shared.dataBase
    
    init(sync: STSync) {
        self.sync = sync
        self.start()
    }
    
    //MARK: - Private func
    
    private func start() {
        
        self.dataBase.galleryProvider.sync(gallery: self.sync.files ?? [])
        
    }
    
}
