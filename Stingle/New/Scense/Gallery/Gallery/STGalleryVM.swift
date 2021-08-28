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
        return galleryProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDFile.dateCreated), #keyPath(STCDFile.file)], sectionNameKeyPath: #keyPath(STCDFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func upload(assets: [PHAsset]) -> STFileUploader.Importer {
        let files = assets.compactMap({ return STFileUploader.FileUploadable(asset: $0) })
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
    
}

extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
