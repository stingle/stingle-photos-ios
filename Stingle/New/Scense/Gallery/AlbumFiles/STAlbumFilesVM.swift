//
//  STAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import Foundation

class STAlbumFilesVM {
    
    private let syncManager = STApplication.shared.syncManager
    
    func createDBDataSource(albumID: String) -> STDataBase.DataSource<STCDAlbumFile> {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
        return STApplication.shared.dataBase.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.albumId), #keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.day), predicate: predicate, cacheName: nil)
    }
    
    func sync() {
        self.syncManager.sync()
    }
        
}

extension STCDAlbumFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}

