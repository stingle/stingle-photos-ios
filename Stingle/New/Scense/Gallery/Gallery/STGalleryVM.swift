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
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        return galleryProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDFile.dateCreated)],
                                                sectionNameKeyPath: #keyPath(STCDFile.day))
    }
    
    
    func sync() {
        self.syncManager.sync()
    }
    
    func upload(assets: [PHAsset]) {
        let files = assets.compactMap({ return STFileUploader.FileUploadable(asset: $0) })
        self.uploader.upload(files: files)
    }
    
}

extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
