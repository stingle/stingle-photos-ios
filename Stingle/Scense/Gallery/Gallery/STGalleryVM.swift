//
//  STGalleryVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Photos
import UIKit
import StingleRoot

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
    
    func upload(assets: [PHAsset]) -> STImporter.GaleryAssetFileImporter {
        let files = assets.compactMap({ return STImporter.GaleryFileAssetImportable(asset: $0) })
        let importer = self.uploader.upload(files: files)
        return importer
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.GaleryFile] {
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        let files = galleryProvider.fetchObjects(fileNames: fileNames)
        return files
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func deleteFile(files: [STLibrary.GaleryFile], completion: @escaping (IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.fileWorker.moveFilesToTrash(files: files, reloadDBData: true)
                completion(nil)
            } catch {
                completion((error as? IError) ?? STError.error(error: error))
            }
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
