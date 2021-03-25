//
//  STGalleryVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Foundation

class STGalleryVM {
    
    private(set) var dataBaseDataSource: STDataBase.DataSource<STLibrary.File>
    private let syncWorker = STSyncWorker()
    private let crypto = STApplication.shared.crypto
    
    init() {
        self.dataBaseDataSource = STApplication.shared.dataBase.galleryProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: #keyPath(STCDFile.day))
        
        self.sync()
    }
    
    func reloadData() {
        self.dataBaseDataSource.reloadData()
    }
    
    func sync(end: ((_ isSuccess: Bool) -> Void)? = nil) {
        self.syncWorker.getUpdates { (_) in
            end?(true)
        } failure: { (error) in
            end?(false)
        }
    }
    
}

extension STGalleryVM {
    
    func sectionTitle(at secction: Int) -> String? {
        return self.dataBaseDataSource.sectionTitle(at: secction)
    }
    
    func object(at indexPath: IndexPath) -> STLibrary.File? {
        if let file = self.dataBaseDataSource.object(at: indexPath) {
            return file
        }
        return nil
    }
    
    func item(at indexPath: IndexPath) -> STGalleryVC.ViewItem? {
        if let obj = self.object(at: indexPath) {
            let image = STImageView.Image(file: obj, isThumb: true)
            return STGalleryVC.ViewItem(image: image, name: obj.file)
        }
        return nil
    }
    
}

extension STGalleryVC {
    
    struct ViewItem {
        let image: STImageView.Image?
        let name: String?
    }
    
}


extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
