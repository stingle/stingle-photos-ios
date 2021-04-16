//
//  STTrashVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation

class STTrashVM {
    
    private(set) var dataBaseDataSource: STDataBase.DataSource<STCDTrashFile>
    private let syncManager = STApplication.shared.syncManager
    private let uploader = STApplication.shared.uploader
    private let cache = NSCache<NSIndexPath, STLibrary.TrashFile>()
    
    init() {
        self.dataBaseDataSource = STApplication.shared.dataBase.trashProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: #keyPath(STCDTrashFile.day))
        self.cache.countLimit = 400
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func reloadData() {
        self.dataBaseDataSource.reloadData()
    }
    
    func removeCache() {
        self.cache.removeAllObjects()
    }
    
}

extension STTrashVM {
    
    func sectionTitle(at secction: Int) -> String? {
        return self.dataBaseDataSource.sectionTitle(at: secction)
    }
    
    func object(at indexPath: IndexPath) -> STLibrary.TrashFile? {
        if let file = self.cache.object(forKey: indexPath as NSIndexPath) {
            return file
        }
        if let cdFile = self.dataBaseDataSource.managedModel(at: indexPath), let file = try? STLibrary.TrashFile(model: cdFile) {
            self.cache.setObject(file, forKey: indexPath as NSIndexPath)
            return file
        }
        return nil
    }
    
    func item(at indexPath: IndexPath) -> STTrashVC.ViewItem? {
        if let obj = self.object(at: indexPath) {
            let image = STImageView.Image(file: obj, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = obj.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).toString()
            }
            return STTrashVC.ViewItem(image: image, name: obj.file, videoDuration: videoDurationStr, isRemote: obj.isRemote)
        }
        return nil
    }
    
}

extension STTrashVC {
    
    struct ViewItem {
        let image: STImageView.Image?
        let name: String?
        let videoDuration: String?
        let isRemote: Bool
    }
    
}

extension STCDTrashFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
