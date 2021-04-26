//
//  STGalleryVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Photos
import UIKit

class STGalleryVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let uploader = STApplication.shared.uploader
    
    func createDBDataSource() -> STDataBase.DataSource<STCDFile> {
        return STApplication.shared.dataBase.galleryProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"],
                                                                              sectionNameKeyPath: #keyPath(STCDFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func upload(assets: [PHAsset]) {
        self.uploader.upload(files: assets)
    }
    
}

extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
