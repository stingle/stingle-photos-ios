//
//  STAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import Foundation

protocol STAlbumFilesVMDelegate: AnyObject {
    func albumFilesVM(didDeletedAlbum albumFilesVM: STAlbumFilesVM)
    func albumFilesVM(didUpdatedAlbum albumFilesVM: STAlbumFilesVM, album: STLibrary.Album)
}

class STAlbumFilesVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let albumWorker = STAlbumWorker()
    private let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
    private let albumProvider = STApplication.shared.dataBase.albumsProvider
    private var album: STLibrary.Album
    
    weak var delegate: STAlbumFilesVMDelegate?
    
    init(album: STLibrary.Album) {
        self.album = album
        self.albumProvider.add(self)
    }
    
    func createDBDataSource() -> STDataBase.DataSource<STCDAlbumFile> {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", self.album.albumId)
        return self.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.albumId), #keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.day), predicate: predicate, cacheName: nil)
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func deleteSelectedFiles(files: [String], result: @escaping ((IError?) -> Void)) {
        let files = STApplication.shared.dataBase.albumFilesProvider.fetchAll(for: self.album.albumId, fileNames: files)
        self.albumWorker.deleteAlbumFiles(album: album, files: files) { responce in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
        
}

extension STAlbumFilesVM: ICollectionProviderObserver {
    
    func dataBaseCollectionProvider(didDeleted provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        guard provider === self.albumProvider, let album = models.first(where: {$0.identifier == self.album.identifier}) as? STLibrary.Album else {
            return
        }
        self.album = album
        self.delegate?.albumFilesVM(didUpdatedAlbum: self, album: album)
    }
    
    func dataBaseCollectionProvider(didUpdated provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        guard provider === self.albumProvider, let album = models.first(where: {$0.identifier == self.album.identifier}) as? STLibrary.Album else {
            return
        }
        
        self.album = album
        self.delegate?.albumFilesVM(didDeletedAlbum: self)
    }
    
}

extension STCDAlbumFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}

