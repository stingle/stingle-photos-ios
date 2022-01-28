//
//  STFileImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/21/21.
//

import Foundation

enum STImporter {
    
    class Importer {
                
        struct Progress {
            let totalUnitCount: Int
            let completedUnitCount: Int
            let fractionCompleted: Double
            let uploadFile: IImportable?
        }
        
        typealias ProgressHendler = (_ progress: Progress) -> Void
        typealias Hendler = () -> Void
        typealias Complition = (_ files: [STLibrary.File], _ importableFiles: [IImportable]) -> Void
        
        static private let importerDispatchQueue = DispatchQueue(label: "Importer.queue", attributes: .concurrent)
        
        static private var operationQueue: STOperationQueue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 5, underlyingQueue: Importer.importerDispatchQueue)
        
        private var operations = Set<Operation>()
        private var completedUnitCount: Int = .zero
        private var importedFiles = [STLibrary.File]()
        private var importedImportableFiles = [IImportable]()
        private var totalProgress = [Int: Double]()
        
        let uploadFiles: [IImportable]
        let responseQueue: DispatchQueue
        
        var startHendler: ProgressHendler?
        var progressHendler: ProgressHendler?
        var complition: Complition?
        
        private var operationQueue: STOperationQueue {
            return Self.operationQueue
        }
        
        private var operationManager: STOperationManager {
            return STOperationManager.shared
        }
        
        init(uploadFiles: [IImportable], responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.uploadFiles = uploadFiles
            self.responseQueue = responseQueue
            
            defer {
                self.startImport(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        func cancel() {
            self.operations.forEach({$0.cancel()})
        }
                
        //MARK: - Private methods
        
        fileprivate func addDB(file: STLibrary.File, reloadData: Bool) {
            let dataBase = STApplication.shared.dataBase
            dataBase.galleryProvider.add(models: [file], reloadData: reloadData)
        }
        
        private func startImport(startHendler:  @escaping Hendler, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            self.responseQueue.asyncAfter(deadline: .now() + 0.1) {
                self.importFiles(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        private func importDidSuccess(file: STLibrary.File, importFile: IImportable, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            
            let totalUnitCount = self.uploadFiles.count
            self.completedUnitCount = self.completedUnitCount + 1
            self.totalProgress[operationIndex] = 1
            self.importedFiles.append(file)
            self.importedImportableFiles.append(importFile)
            
            let isEnded = totalUnitCount == self.completedUnitCount
            self.addDB(file: file, reloadData: isEnded)
            
//            if self.completedUnitCount == 1 {
//                self.cancel()
//            }
            
            if isEnded {
                complition(self.importedFiles, self.importedImportableFiles)
                self.complition?(self.importedFiles, self.importedImportableFiles)
            }
        }
        
        private func importProgress(importFile: IImportable, progress: Foundation.Progress, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            let totalUnitCount = self.uploadFiles.count
            self.totalProgress[operationIndex] = progress.fractionCompleted
            let fractionCompleted = self.totalProgress.map { $0.value }.reduce(0, +) / Double(totalUnitCount)
            let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: self.completedUnitCount, fractionCompleted: fractionCompleted, uploadFile: nil)
            self.progressHendler?(progress)
            progressHendler(progress)
        }
        
        private func importDidFailure(importFile: IImportable, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            let totalUnitCount = self.uploadFiles.count
            self.completedUnitCount = self.completedUnitCount + 1
            self.totalProgress[operationIndex] = 1
            self.importedImportableFiles.append(importFile)
            let isEnded = totalUnitCount == self.completedUnitCount
            if isEnded {
                complition(self.importedFiles, self.importedImportableFiles)
                self.complition?(self.importedFiles, self.importedImportableFiles)
            }
        }
        
        private func importFiles(startHendler: @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            var operationIndex: Int = .zero
            self.uploadFiles.forEach { importFile in
                self.addOperation(importFile: importFile, index: operationIndex, startHendler: startHendler, progressHendler: progressHendler, complition: complition)
                operationIndex = operationIndex + 1
            }
        }
        
        private func addOperation(importFile: IImportable, index: Int, startHendler: @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            var operation: Operation!
            operation = Operation(uploadFile: importFile, operationIndex: index, success: { file in
                self.responseQueue.async(flags: .barrier) {
                    self.importDidSuccess(file: file, importFile: importFile, operationIndex: operation.operationIndex, progressHendler: progressHendler, complition: complition)
                    self.operations.remove(operation)
                }
            }, failure: { error in
                self.responseQueue.async(flags: .barrier) {
                    self.importDidFailure(importFile: importFile, operationIndex: operation.operationIndex, progressHendler: progressHendler, complition: complition)
                    self.operations.remove(operation)
                }
            }, progress: { progress in
                self.responseQueue.async(flags: .barrier) {
                    self.importProgress(importFile: importFile, progress: progress, operationIndex: operation.operationIndex, progressHendler: progressHendler, complition: complition)
                    self.operations.remove(operation)
                }
            })
            self.operationManager.run(operation: operation, in: self.operationQueue)
            self.operations.insert(operation)
        }
      
    }
    
}


extension STImporter {
    
    class AlbumFileImporter: Importer {
        
        let album: STLibrary.Album
        
        init(uploadFiles: [IImportable], album: STLibrary.Album, responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.album = album
            super.init(uploadFiles: uploadFiles, responseQueue: responseQueue, startHendler: startHendler, progressHendler: progressHendler, complition: complition)
        }
        
        override fileprivate func addDB(file: STLibrary.File, reloadData: Bool) {
            guard let albumFile = file as? STLibrary.AlbumFile else {
                fatalError("files not correct")
            }
            let dataBase = STApplication.shared.dataBase
            dataBase.addAlbumFiles(albumFiles: [albumFile], album: self.album, reloadData: true)
        }
        
    }
    
}

extension STImporter.Importer {
    
    class Operation: STOperation<STLibrary.File> {
        
        let uploadFile: IImportable
        let operationIndex: Int
        
        init(uploadFile: IImportable, operationIndex: Int, success: @escaping STOperationSuccess, failure: @escaping STOperationFailure, progress: STOperationProgress?) {
            self.operationIndex = operationIndex
            self.uploadFile = uploadFile
            super.init(success: success, failure: failure, progress: progress)
        }
        
        override func resume() {
            super.resume()
            guard !self.isExpired else {
                return
            }
            self.uploadFile.requestFile(in: self.delegate?.underlyingQueue, progressHandler: { [weak self] progress, stop in
                guard let weakSelf = self else {
                    return
                }
                guard !weakSelf.isCancelled else {
                    weakSelf.delegate?.underlyingQueue?.async { [weak weakSelf] in
                        weakSelf?.responseFailed(error: STError.canceled)
                    }
                    stop = true
                    return
                }
                weakSelf.delegate?.underlyingQueue?.async { [weak weakSelf] in
                    weakSelf?.responseProgress(result: progress)
                }
            }) { [weak self] file in
                self?.responseSucces(result: file)
            } failure: { [weak self] error in
                self?.responseFailed(error: error)
            }
        }
        
        override func cancel() {
            self.responseFailed(error: STError.canceled)
            super.cancel()
        }

    }

}

