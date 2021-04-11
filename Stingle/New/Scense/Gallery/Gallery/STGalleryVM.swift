//
//  STGalleryVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Photos

class STGalleryVM {
    
    private(set) var dataBaseDataSource: STDataBase.DataSource<STLibrary.File>
    private let syncManager = STApplication.shared.syncManager
    private let uploader = STApplication.shared.uploader
    private let crypto = STApplication.shared.crypto
    private let cache = NSCache<NSIndexPath, STLibrary.File>()
    
    init() {
        self.dataBaseDataSource = STApplication.shared.dataBase.galleryProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: #keyPath(STCDFile.day))
        self.cache.countLimit = 400
        self.sync()
    }
    
    func reloadData() {
        self.dataBaseDataSource.reloadData()
    }
    
    func removeCache() {
        self.cache.removeAllObjects()
    }
    
    func sync(end: ((_ isSuccess: Bool) -> Void)? = nil) {
        self.syncManager.sync { [weak self] in
            self?.cache.removeAllObjects()
            end?(true)
        } failure: { (error) in
            end?(false)
        }
    }
    
    func upload(assets: [PHAsset]) {
        
        self.uploader.upload(files: assets)
                
    }
    
}

extension STGalleryVM {
    
    func sectionTitle(at secction: Int) -> String? {
        return self.dataBaseDataSource.sectionTitle(at: secction)
    }
    
    func object(at indexPath: IndexPath) -> STLibrary.File? {
        if let file = self.cache.object(forKey: indexPath as NSIndexPath) {
            return file
        }
        if let file = self.dataBaseDataSource.object(at: indexPath) {
            self.cache.setObject(file, forKey: indexPath as NSIndexPath)
            return file
        }
        return nil
    }
    
    func item(at indexPath: IndexPath) -> STGalleryVC.ViewItem? {
        if let obj = self.object(at: indexPath) {
            let image = STImageView.Image(file: obj, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = obj.encryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).toString()
            }
            return STGalleryVC.ViewItem(image: image, name: obj.file, videoDuration: videoDurationStr)
        }
        return nil
    }
    
}

extension STGalleryVC {
    
    struct ViewItem {
        let image: STImageView.Image?
        let name: String?
        let videoDuration: String?
    }
    
}


extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
