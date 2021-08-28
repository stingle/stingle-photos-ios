//
//  STFileImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/21/21.
//

import Foundation

extension STFileUploader {
    
    class Importer {
        
        struct Progress {
            let totalUnitCount: Int
            let completedUnitCount: Int
        }
        
        typealias ProgressHendler = (_ progress: Progress) -> Void
        typealias Hendler = () -> Void
        typealias Complition = (_ files: [STLibrary.File]) -> Void
        
        let uploadFiles: [IUploadFile]
        let dispatchQueue: DispatchQueue
        
        var startHendler: ProgressHendler?
        var progressHendler: ProgressHendler?
        var complition: Complition?
        
        
        init(uploadFiles: [IUploadFile], dispatchQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.uploadFiles = uploadFiles
            self.dispatchQueue = dispatchQueue
            
            defer {
                self.startImport(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
            
        }
        
        func addDB(files: [STLibrary.File]) -> [STLibrary.File] {
            var galleryFiles = [STLibrary.File]()
            files.forEach { file in
                if file.dbSet == .file {
                    galleryFiles.append(file)
                }
            }
            let dataBase = STApplication.shared.dataBase
            dataBase.galleryProvider.add(models: galleryFiles, reloadData: true)
            return galleryFiles
        }
        
        //MARK: - Private methods
        
        private func startImport(startHendler:  @escaping Hendler, progressHendler: @escaping ProgressHendler, complition:  @escaping Complition) {
            self.dispatchQueue.asyncAfter(deadline: .now() + 0.1) {
                self.importFiles(startHendler: startHendler, progressHendler: progressHendler, complition: complition)
            }
        }
        
        private func importFiles(startHendler: @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            
            let totalUnitCount = self.uploadFiles.count
            var completedUnitCount: Int = .zero
            
            startHendler()
            let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount)
            self.startHendler?(progress)
            var files = [STLibrary.File]()
            
            self.uploadFiles.forEach { uploadFile in
                
                uploadFile.requestFile { file in
                    completedUnitCount = min(completedUnitCount + 1, totalUnitCount)
                    files.append(file)
                    let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount)
                    progressHendler(progress)
                    self.progressHendler?(progress)
                    
                    if totalUnitCount == completedUnitCount {
                        let dbFiles = self.addDB(files: files)
                        complition(dbFiles)
                        self.complition?(dbFiles)
                    }
                    
                } failure: { error in
                    completedUnitCount = min(completedUnitCount + 1, totalUnitCount)
                    let progress = Progress(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount)
                    progressHendler(progress)
                    self.progressHendler?(progress)
                    
                    if totalUnitCount == completedUnitCount {
                        let dbFiles = self.addDB(files: files)
                        complition(dbFiles)
                        self.complition?(dbFiles)
                    }
                }
            }
            
            if totalUnitCount == .zero {
                self.complition?([])
                complition([])
            }
        }
                
    }

}


extension STFileUploader {
    
    class AlbumFileImporter: Importer {
        
        let album: STLibrary.Album
        
        init(uploadFiles: [IUploadFile], album: STLibrary.Album, dispatchQueue: DispatchQueue, startHendler:  @escaping Hendler, progressHendler:  @escaping ProgressHendler, complition:  @escaping Complition) {
            self.album = album
            super.init(uploadFiles: uploadFiles, dispatchQueue: dispatchQueue, startHendler: startHendler, progressHendler: progressHendler, complition: complition)
        }
        
        override func addDB(files: [STLibrary.File]) -> [STLibrary.File] {
            var albumFiles = [STLibrary.AlbumFile]()
            files.forEach { file in
                if let albumFile = file as? STLibrary.AlbumFile  {
                    albumFiles.append(albumFile)
                }
            }
            
            let dataBase = STApplication.shared.dataBase
            dataBase.addAlbumFiles(albumFiles: albumFiles, album: self.album, reloadData: true)
            return albumFiles
            
        }
        
    }
    
    
}



