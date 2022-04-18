//
//  STFileImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/21/21.
//

import Foundation
import UIKit

enum STImporter {
    
    class Importer {
                
        struct Progress {
            let totalUnitCount: Int
            let completedUnitCount: Int
            let fractionCompleted: Double
            let importingFile: IImportable?
        }
        
        typealias ProgressHendler = (_ progress: Progress) -> Void
        typealias Hendler = () -> Void
        typealias Complition = (_ files: [STLibrary.File], _ importableFiles: [IImportable]) -> Void
        
        static private let importerDispatchQueue = DispatchQueue(label: "Importer.queue", attributes: .concurrent)
        
        static private var operationQueue: STOperationQueue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 3, underlyingQueue: Importer.importerDispatchQueue)
        
        private var operations = Set<Operation>()
        private var completedUnitCount: Int = .zero
        private var importedFiles = [STLibrary.File]()
        private var importedImportableFiles = [IImportable]()
        private var totalProgress = [Int: Double]()
        private var uploadIfNeeded: Bool
        
        let importFiles: [IImportable]
        let responseQueue: DispatchQueue
        
        var startHendler: ProgressHendler?
        var progressHendler: ProgressHendler?
        var complition: Complition?
        
        private var operationQueue: STOperationQueue
        
        private var operationManager: STOperationManager {
            return STOperationManager.shared
        }
        
        init(importFiles: [IImportable], responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.importFiles = importFiles
            self.responseQueue = responseQueue
            self.operationQueue = Self.operationQueue
            self.uploadIfNeeded = false
            
            defer {
                self.startImport(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        init(importFiles: [IImportable], operationQueue: STOperationQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition, uploadIfNeeded: Bool) {
            self.importFiles = importFiles
            self.responseQueue = operationQueue.underlyingQueue ?? Self.importerDispatchQueue
            self.operationQueue = operationQueue
            self.uploadIfNeeded = uploadIfNeeded
            
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
        
        private func complitionImport(complition:  @escaping Complition) {
            self.responseQueue.async(flags: .barrier) {
                let importedFiles = self.importedFiles
                let importedImportableFiles = self.importedImportableFiles
                self.responseQueue.async {
                    complition(importedFiles, importedImportableFiles)
                    self.complition?(importedFiles, importedImportableFiles)
                }
            }
        }
        
        private func importDidSuccess(file: STLibrary.File, importFile: IImportable, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            
            let totalUnitCount = self.importFiles.count
            self.completedUnitCount = self.completedUnitCount + 1
            self.totalProgress[operationIndex] = 1
            self.importedFiles.append(file)
            self.importedImportableFiles.append(importFile)
            
            let isEnded = totalUnitCount == self.completedUnitCount
            self.addDB(file: file, reloadData: isEnded)

            if isEnded {
                if !self.importedFiles.isEmpty, self.uploadIfNeeded {
                    STApplication.shared.uploader.upload(files: self.importedFiles)
                }
                self.complitionImport(complition: complition)
            }
        }
        
        private func importProgress(importFile: IImportable, progress: Foundation.Progress, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            let totalUnitCount = self.importFiles.count
            self.totalProgress[operationIndex] = progress.fractionCompleted
            let fractionCompleted = self.totalProgress.map { $0.value }.reduce(0, +) / Double(totalUnitCount)
            let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: self.completedUnitCount, fractionCompleted: fractionCompleted, importingFile: importFile)
            self.progressHendler?(progress)
            progressHendler(progress)
        }
        
        private func importDidFailure(importFile: IImportable, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            let totalUnitCount = self.importFiles.count
            self.completedUnitCount = self.completedUnitCount + 1
            self.totalProgress[operationIndex] = 1
            let isEnded = totalUnitCount == self.completedUnitCount
            if isEnded {
                if !self.importedFiles.isEmpty, self.uploadIfNeeded {
                    STApplication.shared.uploader.upload(files: self.importedFiles)
                }
                self.complitionImport(complition: complition)
            }
        }
        
        private func importFiles(startHendler: @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            
            guard !self.importFiles.isEmpty else {
                self.complitionImport(complition: complition)
                return
            }
            
            var operationIndex: Int = .zero
            self.importFiles.forEach { importFile in
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
            super.init(importFiles: uploadFiles, responseQueue: responseQueue, startHendler: startHendler, progressHendler: progressHendler, complition: complition)
        }
        
        override fileprivate func addDB(file: STLibrary.File, reloadData: Bool) {
            guard let albumFile = file as? STLibrary.AlbumFile else {
                fatalError("files not correct")
            }
            let dataBase = STApplication.shared.dataBase
            dataBase.addAlbumFiles(albumFiles: [albumFile], album: self.album, reloadData: reloadData)
        }
        
    }
    
}

extension STImporter.Importer {
    
    class Operation: STOperation<STLibrary.File> {
        
        let uploadFile: IImportable
        let operationIndex: Int
        private var isEnded: Bool = false
        
        init(uploadFile: IImportable, operationIndex: Int, success: @escaping STOperationSuccess, failure: @escaping STOperationFailure, progress: STOperationProgress?) {
            
            self.operationIndex = operationIndex
            self.uploadFile = uploadFile
            super.init(success: success, failure: failure, progress: progress)
        }
                
        override func resume() {
            super.resume()
                        
            guard !self.isEnded else {
                self.responseFailed(error: STError.canceled)
                                
                return
            }
                        
            self.uploadFile.requestFile(in: self.delegate?.underlyingQueue, progressHandler: { [weak self] progress, stop in
                guard let weakSelf = self else {
                    return
                }
                guard !weakSelf.isEnded else {
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
            self.isEnded = true
        }

    }

}

