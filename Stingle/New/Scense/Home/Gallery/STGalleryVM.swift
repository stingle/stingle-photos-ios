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
        
        self.syncWorker.getUpdates { (_) in
           print("")
        } failure: { (error) in
            print("")
        }
    }
    
    func reloadData() {
        self.dataBaseDataSource.reloadData()
    }
    
}

extension STGalleryVM {
    
    func sectionTitle(at secction: Int) -> String? {
        return self.dataBaseDataSource.sectionTitle(at: secction)
    }
    
    func object(at indexPath: IndexPath) -> STLibrary.File? {
        if let file = self.dataBaseDataSource.object(at: indexPath) {
//            let headers = self.crypto.getHeaders(file: file)
            return file
        }
        return nil
    }
    
    func item(at indexPath: IndexPath) -> STGalleryVC.ViewItem? {
        
//        let indexPath = IndexPath(row: 3, section: 1)
        
        
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
