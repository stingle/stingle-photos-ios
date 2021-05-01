//
//  STAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import Foundation

class STAlbumFilesVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let albumWorker = STAlbumWorker()
    
    func createDBDataSource(albumID: String) -> STDataBase.DataSource<STCDAlbumFile> {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", albumID)
        return STApplication.shared.dataBase.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.albumId), #keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.day), predicate: predicate, cacheName: nil)
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func deleteSelectedFiles(album: STLibrary.Album, files: [String], result: @escaping ((IError?) -> Void)) {
        let files = STApplication.shared.dataBase.albumFilesProvider.fetchAll(for: album.albumId, fileNames: files)
        self.albumWorker.deleteAlbumFiles(album: album, files: files) { responce in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
        
}

extension STCDAlbumFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}

