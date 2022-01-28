//
//  STFileAutoImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 12/16/21.
//

import Foundation
import Photos
import UIKit

extension STImporter {
    
    class AuotImporter {
        
        enum ImportData {
            case existingFilesDate
            case currentDate
            case coustom(date: Date)
        }
        
        private let dispatchQueue = DispatchQueue(label: "AuotImporter.queue", attributes: .concurrent)
        
        private var importSettings: STAppSettings.Import {
            return STAppSettings.current.import
        }
        
        lazy private var queue: STOperationQueue = {
            return STOperationManager.shared.createQueue(maxConcurrentOperationCount: 1, underlyingQueue: self.dispatchQueue)
        }()
        
        private var lastImportDate: Date? {
            set {
                UserDefaults.standard.set(newValue, forKey: "auotImporter.lastImportDate")
            } get {
                return (UserDefaults.standard.object(forKey: "auotImporter.lastImportDate") as? Date)
            }
        }
        
        private var fetchLimit: Int = 5
        private var isStarted: Bool = false
        private var isImporting: Bool = false
        private var importFilesCount: Int = .zero
        
        private var endImportingCallBack: (() -> Void)?
        
        //MARK: - Public methods
        
        init() {
            STAppSettings.current.addObserver(self)
        }
        
        func startImport() {
            guard !self.isStarted else {
                return
            }
            self.isStarted = true
            self.deleteImportedFiles { [weak self] in
                self?.startImportAssets()
            }
        }
        
        func resetImportDate(date: ImportData, startImport: Bool) {
            
        }
        
        func resetImportDate() {
            
            self.cancelImporting {
                print("")
            }

        }
        
        func setImpor(existingFiles: Bool) throws {
            guard !self.isImporting else {
                throw AuotImporterError.importerIsBusy
            }
            self.lastImportDate = existingFiles ? nil : Date()
        }
        
        func logout() {
            self.endImportIng()
            self.lastImportDate = nil
        }
        
        //MARK: - Private methods
        
        private func cancelImporting(end: (() -> Void)?) {
            self.endImportingCallBack = { [weak self] in
                end?()
            }
            self.queue.cancelAllOperations()
        }
        
        private func deleteImportedFiles(completion: @escaping (() -> Void)) {
            guard STPHPhotoHelper.authorizationStatus != nil, STAppSettings.current.import.isDeleteOriginalFilesAfterAutoImport else {
                self.dispatchQueue.async {
                    completion()
                }
                return
            }
            let albumName = STEnvironment.current.photoLibraryTrashAlbumName
            STPHPhotoHelper.deleteFiles(albumName: albumName) { [weak self] end in
                if end == false {
                    STPHPhotoHelper.removeFiles(albumName: albumName) { _ in
                        self?.dispatchQueue.async {
                            completion()
                        }
                    }
                } else {
                    self?.dispatchQueue.async {
                        completion()
                    }
                }
            }
        }
                
        private func startImportAssets() {
            self.isImporting = true
            self.startNextImport()
        }
        
        private func endImportIng() {
            guard self.isStarted else {
                return
            }
            self.queue.cancelAllOperations()
            self.isImporting = false
          
            if self.importFilesCount == .zero {
                self.importFilesCount = .zero
                self.isStarted = false
                self.didEndImportIng()
            } else {
                self.deleteImportedFiles { [weak self] in
                    self?.isStarted = false
                    self?.importFilesCount = .zero
                    self?.didEndImportIng()
                }
            }
        }
        
        private func didEndImportIng() {
            self.endImportingCallBack?()
            self.endImportingCallBack = nil
        }
        
        private func startNextImport() {
            
            let operation = Operation(success: { [weak self] importCount in
                guard let weakSelf = self else {
                    return
                }
                                
                if importCount != .zero {
                    weakSelf.dispatchQueue.asyncAfter(wallDeadline: .now() + 0.5) { [weak weakSelf] in
                        weakSelf?.startNextImport()
                    }
                    weakSelf.importFilesCount = weakSelf.importFilesCount + (importCount ?? .zero)
                } else {
                    weakSelf.endImportIng()
                }
            }, failure: { [weak self] error in
                self?.endImportIng()
            }, progress: { [weak self] progress in
                
                if let date = progress.userInfo[.dateKey] as? Date {
                    
                    if let lastImportDate = self?.lastImportDate, date > lastImportDate {
                        self?.lastImportDate = date
                    } else if self?.lastImportDate == nil {
                        self?.lastImportDate = date
                    }
                }
                
            }, fromDate: self.lastImportDate, fetchLimit: self.fetchLimit)
                        
            operation.didStartRun(with: self.queue)
        }
             
    }
    
}

extension STImporter.AuotImporter: ISettingsObserver {
    
    func appSettings(didChange settings: STAppSettings, import: STAppSettings.Import) {
        if `import`.isAutoImportEnable {
            self.startImport()
        } else {
            self.endImportIng()
        }
    }
    
}

extension STImporter.AuotImporter {
    
    enum AuotImporterError: IError {
       
        case cantImportFiles
        case canceled
        case importerIsBusy
        
        var message: String {
            switch self {
            case .cantImportFiles:
                return "Can't import files"
            case .canceled:
                return "error_canceled".localized
            case .importerIsBusy:
                return "importerIsBusy"
            }
        }
    }
            
    class Operation: STOperation<Int?> {
        
        let date: Date?
        let fetchLimit: Int
        private var importer: STImporter.Importer?
        private var progress: Progress
        
        init(success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?, fromDate: Date?, fetchLimit: Int) {
            self.progress = Progress(totalUnitCount: Int64(fetchLimit))
            self.fetchLimit = fetchLimit
            self.date = fromDate
            super.init(success: success, failure: failure, progress: progress)
        }
        
        //MARK: - override methods
        
        override func cancel() {
            super.cancel()
            print("Operation", self.uuid, "cancel isExpired =", isExpired, isCancelled, status)
        }
        
        override func responseSucces(result: Int?) {
            super.responseSucces(result: result)
            print("Operation", self.uuid, "responseSucces isExpired =", isExpired, isCancelled, status)
        }
        
        override func responseProgress(result: Progress) {
            super.responseProgress(result: result)
            print("Operation", self.uuid, "responseProgress isExpired =", isExpired, isCancelled, status)
        }
        
        override func resume() {
            super.resume()
            self.canImportFiles { [weak self] canImport in
                if canImport {
                    self?.enumerateObjects()
                } else {
                    self?.responseFailed(error: AuotImporterError.canceled)
                }
            }
        }
        
        //MARK: - Private methods
        
        private func enumerateObjects() {
            var uploadables = [STImporter.FileUploadable]()
            self.enumerateObjects { asset, index, stop in
                if self.isExpired {
                    stop.pointee = true
                    return
                }
                let uploadable = STImporter.FileUploadable(asset: asset)
                uploadables.append(uploadable)
            }
            guard !self.isExpired else {
                return
            }
            self.startImport(uploadables: uploadables)
        }
        
        private func startImport(uploadables: [STImporter.FileUploadable]) {

            guard let queue = self.delegate?.underlyingQueue else {
                self.responseFailed(error: AuotImporterError.canceled)
                return
            }
            
            let importer = STApplication.shared.uploader.upload(files: uploadables)
            var resultDate = self.date
            
            var importedAssets = [PHAsset]()
                        
            importer.progressHendler = { [weak self] progress in
                queue.async {
                    guard let weakSelf = self else {
                        return
                    }
                    if let asset = (progress.uploadFile as? STImporter.FileUploadable)?.asset {
                        importedAssets.append(asset)
                    }
                    let currentFileDate = (progress.uploadFile as? STImporter.FileUploadable)?.asset.creationDate
                    if let date = resultDate {
                        let fileDate: Date = currentFileDate ?? date
                        resultDate = max(date, fileDate)
                    } else {
                        resultDate = currentFileDate
                    }
                    weakSelf.progress.setUserInfoObject(resultDate, forKey: ProgressUserInfoKey.dateKey)
                    weakSelf.progress.completedUnitCount = Int64(progress.completedUnitCount)
                    weakSelf.responseProgress(result: weakSelf.progress)
                }
            }
            
            importer.complition = { [weak self] files, _ in
                func response(count: Int) {
                    queue.async { [weak self] in
                        guard let weakSelf = self else {
                            return
                        }
                        if weakSelf.isCancelled {
                            weakSelf.responseFailed(error: AuotImporterError.canceled)
                        } else {
                            weakSelf.responseSucces(result: count)
                        }
                    }
                }
                
                
                if STAppSettings.current.import.isDeleteOriginalFilesAfterAutoImport {
                    let albumName = STEnvironment.current.photoLibraryTrashAlbumName
                    STPHPhotoHelper.moveToAlbum(albumName: albumName, assets: importedAssets) {
                        response(count: files.count)
                    }
                } else {
                    response(count: files.count)
                }
            }
            
            self.importer = importer
        }
        
        private func enumerateObjects(_ block: @escaping (PHAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
            let options = PHFetchOptions()
            options.includeHiddenAssets = true
            
            let sortDescriptor = NSSortDescriptor(key: "\(#keyPath(PHAsset.creationDate))", ascending: true)
            options.sortDescriptors = [sortDescriptor]
            options.fetchLimit = self.fetchLimit
                        
            if let lastImportDate = self.date {
                let predicate = NSPredicate(format: "\(#keyPath(PHAsset.creationDate)) > %@", lastImportDate as CVarArg)
                options.predicate = predicate
            }
            let assets = PHAsset.fetchAssets(with: options)
            assets.enumerateObjects({ (asset, index, pointerEnd) in
                block(asset, index, pointerEnd)
            })
            
        }
        
        private func canImportFiles(completion: @escaping (Bool) -> Void) {
            guard STAppSettings.current.import.isAutoImportEnable, let queue = self.delegate?.underlyingQueue  else {
                completion(false)
                return
            }
            STPHPhotoHelper.checkAndReqauestAuthorization(queue: queue) { status in
                let settings = STAppSettings.current.import
                let result = settings.isAutoImportEnable && status == .authorized
                completion(result)
            }
        }
        
    }
    
}

fileprivate extension ProgressUserInfoKey {
    
    static var dateKey: ProgressUserInfoKey {
        return ProgressUserInfoKey(rawValue: "date")
    }
    
}
