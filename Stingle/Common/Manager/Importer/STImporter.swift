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
            let uploadFile: IUploadFile?
        }
        
        typealias ProgressHendler = (_ progress: Progress) -> Void
        typealias Hendler = () -> Void
        typealias Complition = (_ files: [STLibrary.File]) -> Void
        
        
        static private let importerDispatchQueue = DispatchQueue(label: "Importer.queue", attributes: .concurrent)
        
        static private var operationQueue: STOperationQueue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 5, underlyingQueue: Importer.importerDispatchQueue)
        
        let uploadFiles: [IUploadFile]
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
        
        init(uploadFiles: [IUploadFile], responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.uploadFiles = uploadFiles
            self.responseQueue = responseQueue
            
            defer {
                self.startImport(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
            
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
        
        private func importFiles(startHendler: @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            
            let totalUnitCount = self.uploadFiles.count
            var completedUnitCount: Int = .zero
            
            startHendler()
            let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount, uploadFile: nil)
            self.startHendler?(progress)
            var files = [STLibrary.File]()
            
            self.uploadFiles.forEach { uploadFile in
                let operation = Operation(uploadFile: uploadFile) { result in
                    self.responseQueue.async(flags: .barrier) {
                        files.append(result)
                        completedUnitCount = min(completedUnitCount + 1, totalUnitCount)
                        let isComplited = totalUnitCount == completedUnitCount
                        self.addDB(file: result, reloadData: isComplited)
                        let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount, uploadFile: uploadFile)
                        progressHendler(progress)
                        self.progressHendler?(progress)
                        if isComplited {
                            complition(files)
                            self.complition?(files)
                        }
                    }
                    
                } failure: { error in
                    
                    self.responseQueue.async(flags: .barrier) {
                        completedUnitCount = min(completedUnitCount + 1, totalUnitCount)
                        let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount, uploadFile: uploadFile)
                        progressHendler(progress)
                        self.progressHendler?(progress)
                        if totalUnitCount == completedUnitCount {
                            self.complition?(files)
                        }
                    }
                    
                }
                self.operationManager.run(operation: operation, in: self.operationQueue)
            }
            
            if totalUnitCount == .zero {
                self.responseQueue.async {
                    self.complition?([])
                    complition([])
                }
            }
        }
        
        func canImport() -> Bool {
            return false
        }
      
    }
    
}


extension STImporter {
    
    class AlbumFileImporter: Importer {
        
        let album: STLibrary.Album
        
        init(uploadFiles: [IUploadFile], album: STLibrary.Album, responseQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
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
        
        let uploadFile: IUploadFile

        init(uploadFile: IUploadFile, success: @escaping STOperationSuccess, failure: @escaping STOperationFailure) {
            self.uploadFile = uploadFile
            super.init(success: success, failure: failure)
        }
        
        override func resume() {
            super.resume()
            self.uploadFile.requestFile(in: self.delegate?.underlyingQueue) { [weak self] file in
                self?.responseSucces(result: file)
            } failure: { [weak self] error in
                self?.responseFailed(error: error)
            }
        }
        
        override func cancel() {
            super.cancel()
            self.responseFailed(error: STError.canceled)
        }

    }
    
}

