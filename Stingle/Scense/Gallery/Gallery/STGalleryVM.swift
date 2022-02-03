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
    
    func createDBDataSource() -> STDataBase.DataSource<STCDFile> {
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        let sorting = self.getSorting()
        return galleryProvider.createDataSource(sortDescriptorsKeys: sorting, sectionNameKeyPath: #keyPath(STCDFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func upload(assets: [PHAsset]) -> STImporter.Importer {
        let files = assets.compactMap({ return STImporter.FileUploadable(asset: $0) })
        let importer = self.uploader.upload(files: files)
        return importer
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.File] {
        let files = STApplication.shared.dataBase.galleryProvider.fetchAll(for: fileNames)
        return files
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func deleteFile(files: [STLibrary.File], completion: @escaping (IError?) -> Void) {
        self.fileWorker.moveFilesToTrash(files: files, reloadDBData: true) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func getSorting() -> [STDataBase.DataSource<STCDFile>.Sort] {
        let dateCreated = STDataBase.DataSource<STCDFile>.Sort(key: #keyPath(STCDFile.dateCreated), ascending: nil)
        let dateModified = STDataBase.DataSource<STCDFile>.Sort(key: #keyPath(STCDFile.dateModified), ascending: true)
        let file = STDataBase.DataSource<STCDFile>.Sort(key: #keyPath(STCDFile.file), ascending: true)
        return [dateCreated, dateModified, file]
    }
    
}

extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
