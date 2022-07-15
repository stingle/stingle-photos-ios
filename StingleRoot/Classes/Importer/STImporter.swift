//
//  STFileImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/21/21.
//

import Foundation
import UIKit

public enum STImporter {
    
    static private let importerDispatchQueue = DispatchQueue(label: "Importer.queue", attributes: .concurrent)
    
    static private var importerOperationQueue: STOperationQueue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 3, underlyingQueue: STImporter.importerDispatchQueue)
    
    public class Importer<Importable: IImportableFile> {
        
        public struct Progress {
            public let totalUnitCount: Int
            public let completedUnitCount: Int
            public let fractionCompleted: Double
            public let importingFile: Importable?
        }
        
        public typealias File = Importable.File
        
        public typealias ProgressHendler = (_ progress: Progress) -> Void
        public typealias Hendler = () -> Void
        public typealias Complition = (_ files: [File], _ importableFiles: [Importable]) -> Void
        
        private var operations = Set<Operation<Importable>>()
        private var completedUnitCount: Int = .zero
        private var importedFiles = [File]()
        private var importedImportableFiles = [Importable]()
        private var totalProgress = [Int: Double]()
        private var uploadIfNeeded: Bool
        
        let importFiles: [Importable]
        let responseQueue: DispatchQueue
        
        public var startHendler: ProgressHendler?
        public var progressHendler: ProgressHendler?
        public var complition: Complition?
        
        private var operationQueue: STOperationQueue
        
        private var operationManager: STOperationManager {
            return STOperationManager.shared
        }
        
        public init(importFiles: [Importable], responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.importFiles = importFiles
            self.responseQueue = responseQueue
            self.operationQueue = STImporter.importerOperationQueue
            self.uploadIfNeeded = false
            
            defer {
                self.startImport(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        public init(importFiles: [Importable], operationQueue: STOperationQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition, uploadIfNeeded: Bool) {
            self.importFiles = importFiles
            self.responseQueue = operationQueue.underlyingQueue ?? STImporter.importerDispatchQueue
            self.operationQueue = operationQueue
            self.uploadIfNeeded = uploadIfNeeded
                        
            defer {
                self.startImport(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        public func cancel() {
            self.operations.forEach({$0.cancel()})
        }
                
        //MARK: - Private methods
        
        fileprivate func addDB(file: File, reloadData: Bool) {
            fatalError("implement chide classes")
        }
                
        private func startImport(startHendler:  @escaping Hendler, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            self.responseQueue.asyncAfter(deadline: .now() + 0.1) {
                self.startImport(start: startHendler)
                self.importFiles(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        private func startImport(start: @escaping Hendler) {
            self.responseQueue.async(flags: .barrier) {
                self.responseQueue.async {
                    let progress = Importer.Progress(totalUnitCount: self.importFiles.count, completedUnitCount: .zero, fractionCompleted: .zero, importingFile: nil)
                    start()
                    self.startHendler?(progress)
                }
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
        
        private func importDidSuccess(file: File, importFile: Importable, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            
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
        
        private func importProgress(importFile: Importable, progress: Foundation.Progress, operationIndex: Int, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
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
        
        private func addOperation(importFile: Importable, index: Int, startHendler: @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            var operation:  Operation<Importable>!
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


public extension STImporter {
    
    class GaleryFileImporter<Importable: GaleryImportable>: Importer<Importable> {
        
        override func addDB(file: Importer<Importable>.File, reloadData: Bool) {
            let dataBase = STApplication.shared.dataBase
            dataBase.galleryProvider.add(models: [file], reloadData: reloadData)
        }

    }
    
    class AlbumFileImporter<Importable: AlbumFileImportable>: Importer<Importable> {

        let album: STLibrary.Album
        
        public init(album: STLibrary.Album, importFiles: [Importable], responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.album = album
            super.init(importFiles: importFiles, responseQueue: responseQueue, startHendler: startHendler, progressHendler: progressHendler, complition: complition)
        }
        
        init(album: STLibrary.Album, importFiles: [Importable], operationQueue: STOperationQueue, startHendler: @escaping STImporter.Importer<Importable>.Hendler, progressHendler: @escaping STImporter.Importer<Importable>.ProgressHendler, complition: @escaping STImporter.Importer<Importable>.Complition, uploadIfNeeded: Bool) {
            self.album = album
            super.init(importFiles: importFiles, operationQueue: operationQueue, startHendler: startHendler, progressHendler: progressHendler, complition: complition, uploadIfNeeded: uploadIfNeeded)
        }

        override func addDB(file: STImporter.Importer<Importable>.File, reloadData: Bool) {
            let dataBase = STApplication.shared.dataBase
            dataBase.addAlbumFiles(albumFiles: [file], album: self.album, reloadData: reloadData)
        }
    }

}

public extension STImporter {
    
    typealias GaleryAssetFileImporter = GaleryFileImporter<GaleryFileAssetImportable>
    typealias AlbumAssetFileImporter = AlbumFileImporter<AlbumFileAssetImportable>
    
}

extension STImporter.Importer {
    
    class Operation<ImportableFile: IImportableFile>: STOperation<ImportableFile.File> {
        
        let uploadFile: ImportableFile
        let operationIndex: Int
        private var isEnded: Bool = false
        
        init(uploadFile: ImportableFile, operationIndex: Int, success: @escaping STOperationSuccess, failure: @escaping STOperationFailure, progress: STOperationProgress?) {
            
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

