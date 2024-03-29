//
//  STTrashVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation
import StingleRoot

class STTrashVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let fileWorker = STFileWorker()
    private let trashProvider = STApplication.shared.dataBase.trashProvider
    
    func createDBDataSource() -> STDataBase.DataSource<STLibrary.TrashFile> {
        let trashProvider = STApplication.shared.dataBase.trashProvider
        let sorting = self.getSorting()
        return trashProvider.createDataSource(sortDescriptorsKeys: sorting, sectionNameKeyPath: #keyPath(STCDTrashFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.TrashFile] {
        let files = self.trashProvider.fetchObjects(fileNames: fileNames)
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
        let files = self.trashProvider.fetchObjects()
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
        let files = self.trashProvider.fetchObjects()
        self.fileWorker.moveToGalery(files: files) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func getSorting() -> [STDataBase.DataSource<STLibrary.TrashFile>.Sort] {
        let dateCreated = STDataBase.DataSource<STLibrary.TrashFile>.Sort(key: #keyPath(STCDTrashFile.dateCreated), ascending: nil)
        let dateModified = STDataBase.DataSource<STLibrary.TrashFile>.Sort(key: #keyPath(STCDTrashFile.dateModified), ascending: false)
        let file = STDataBase.DataSource<STLibrary.TrashFile>.Sort(key: #keyPath(STCDTrashFile.file), ascending: false)
        return [dateCreated, dateModified, file]
    }
    
}
