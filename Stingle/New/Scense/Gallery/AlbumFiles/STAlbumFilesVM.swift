//
//  STAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import Foundation
import Photos

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
    private let uploader = STApplication.shared.uploader
    
    weak var delegate: STAlbumFilesVMDelegate?
    
    init(album: STLibrary.Album) {
        self.album = album
        self.albumProvider.add(self)
    }
    
    func createDBDataSource() -> STDataBase.DataSource<STCDAlbumFile> {
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", self.album.albumId)
        return self.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.day), predicate: predicate, cacheName: nil)
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func deleteFiles(files: [String], result: @escaping ((IError?) -> Void)) {
        let files = self.getFiles(fileNames: files)
        self.albumWorker.deleteAlbumFiles(album: album, files: files) { responce in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.AlbumFile] {
        let files = STApplication.shared.dataBase.albumFilesProvider.fetchAll(for: self.album.albumId, fileNames: fileNames)
        return files
    }
    
    func getAlbumAction(fileNames: [String]?) throws -> [STAlbumFilesVC.AlbumAction] {
        if !self.album.isOwner {
            if let fileNames = fileNames {
                if fileNames.isEmpty {
                    throw AlbumFilesError.emptySelectedFiles
                }
                return [.downloadSelection]
            } else {
                return [.leave]
            }
        } else {
            if let fileNames = fileNames {
                if fileNames.isEmpty {
                    throw AlbumFilesError.emptySelectedFiles
                }
                if fileNames.count == 1 {
                    return [.setCover, .downloadSelection]
                }
                return [.downloadSelection]
            } else {
                return [.rename, .setBlankCover, .resetBlankCover, .delete]
            }
        }
    }
    
    func renameAlbum(newName: String?, result: @escaping ((IError?) -> Void)) {
        self.albumWorker.rename(album: self.album, name: newName) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func setBlankCover(result: @escaping ((IError?) -> Void)) {
        let cover = STLibrary.Album.imageBlankImageName
        self.albumWorker.setCover(album: self.album, caver: cover) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func resetBlankCover(result: @escaping ((IError?) -> Void)) {
        self.albumWorker.setCover(album: self.album, caver: nil) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func delete(result: @escaping ((IError?) -> Void)) {
        self.albumWorker.deleteAlbumWithFiles(album: self.album) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func leave(result: @escaping ((IError?) -> Void)) {
        self.albumWorker.leaveAlbum(album: self.album) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func setCover(fileName: String, result: @escaping ((IError?) -> Void)) {
        self.albumWorker.setCover(album: self.album, caver: fileName) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func downloadSelection(fileNames: [String]) {
        let files = self.getFiles(fileNames: fileNames)
        STApplication.shared.downloaderManager.fileDownloader.download(files: files)
    }
    
    func upload(assets: [PHAsset]) {
        let files = assets.compactMap({ return STFileUploader.AlbumFileUploadable(asset: $0, album: self.album) })
        self.uploader.uploadAlbum(files: files, album: self.album)
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
}

extension STAlbumFilesVM: ICollectionProviderObserver {
    
    func dataBaseCollectionProvider(didDeleted provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        guard provider === self.albumProvider, let album = models.first(where: {$0.identifier == self.album.identifier}) as? STLibrary.Album else {
            return
        }
        self.album = album
        self.delegate?.albumFilesVM(didDeletedAlbum: self)
    }
    
    func dataBaseCollectionProvider(didUpdated provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        guard provider === self.albumProvider, let album = models.first(where: {$0.identifier == self.album.identifier}) as? STLibrary.Album else {
            return
        }
        self.album = album
        self.delegate?.albumFilesVM(didUpdatedAlbum: self, album: album)
    }
    
}

extension STAlbumFilesVM {
    
    enum AlbumFilesError: IError {
        case hasIsRemoteItems
        case emptyData
        case emptySelectedFiles
        
        var message: String {
            switch self {
            case .hasIsRemoteItems:
                return "please_wait_for_backup_to_finish_before_you_can_proceed".localized
            case .emptyData:
                return "empty_data".localized
            case .emptySelectedFiles:
                return "please_select_items".localized
            }
        }
    }
    
}


extension STCDAlbumFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}

