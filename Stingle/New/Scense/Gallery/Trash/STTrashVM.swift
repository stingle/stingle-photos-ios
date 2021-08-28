//
//  STTrashVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation

class STTrashVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let fileWorker = STFileWorker()
    private let trashProvider = STApplication.shared.dataBase.trashProvider
    
    func createDBDataSource() -> STDataBase.DataSource<STCDTrashFile> {
        let trashProvider = STApplication.shared.dataBase.trashProvider
        return trashProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDTrashFile.dateCreated), #keyPath(STCDTrashFile.file)], sectionNameKeyPath: #keyPath(STCDTrashFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.TrashFile] {
        let files = self.trashProvider.fetchAll(for: fileNames)
        return files
    }
    
    func delete(files: [STLibrary.TrashFile], completion: @escaping (IError?) -> Void) {
        self.fileWorker.deleteFiles(files: files) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func deleteAll(completion: @escaping (IError?) -> Void) {
        let files = self.trashProvider.fetchAllObjects()
        self.fileWorker.deleteFiles(files: files) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func recover(files: [STLibrary.TrashFile], completion: @escaping (IError?) -> Void) {
        self.fileWorker.moveToGalery(files: files) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func recoverAll(completion: @escaping (IError?) -> Void) {
        let files = self.trashProvider.fetchAllObjects()
        self.fileWorker.moveToGalery(files: files) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
}

extension STCDTrashFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
