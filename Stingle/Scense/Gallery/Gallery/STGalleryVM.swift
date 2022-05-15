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
    private let fileWorker = STFileWorker()
    
    func createDBDataSource() -> STDataBase.DataSource<STLibrary.GaleryFile> {
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        let sorting = self.getSorting()
        return galleryProvider.createDataSource(sortDescriptorsKeys: sorting, sectionNameKeyPath: #keyPath(STCDFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func upload(assets: [PHAsset]) -> STImporter.GaleryFileImporter {
        let files = assets.compactMap({ return STImporter.GaleryFileImportable(asset: $0) })
        let importer = self.uploader.upload(files: files)
        return importer
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.GaleryFile] {
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        let files = galleryProvider.fetchAll(for: fileNames)
        return files
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func deleteFile(files: [STLibrary.GaleryFile], completion: @escaping (IError?) -> Void) {
        self.fileWorker.moveFilesToTrash(files: files, reloadDBData: true) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func getSorting() -> [STDataBase.DataSource<STLibrary.GaleryFile>.Sort] {
        let dateCreated = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.dateCreated), ascending: nil)
        let dateModified = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.dateModified), ascending: true)
        let file = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.file), ascending: true)
        return [dateCreated, dateModified, file]
    }
    
}

extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
