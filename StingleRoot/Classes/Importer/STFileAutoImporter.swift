//
//  STFileAutoImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 12/16/21.
//

import Foundation
import Photos
import UIKit

public protocol IAutoImporterObserver: AnyObject {
    func autoImporter(didStart autoImporter: STImporter.AutoImporter)
    func autoImporter(didEnd autoImporter: STImporter.AutoImporter)
}

public extension STImporter {
    
    class AutoImporter {
        
        public enum ImportData {
            case setupDate
            case currentDate
            case coustom(date: Date)
            
            var date: Date? {
                switch self {
                case .setupDate:
                    return nil
                case .currentDate:
                    return Date()
                case .coustom(let date):
                    return date
                }
            }
        }
        
        private var fetchLimit: Int = 5
        private var isStarted: Bool = false
        private var isImporting: Bool = false
        private var importFilesCount: Int = .zero
        private var canSetDate = true
        private var endImportingCallBack: (() -> Void)?
        
        private let observerEvents = STObserverEvents<IAutoImporterObserver>()
        private var importQueue: STOperationQueue
        private var autoImportQueue: STOperationQueue
        private weak var currentOporation: Operation?
        public let dispatchQueue = DispatchQueue(label: "AutoImporter.queue")
                        
        private var importSettings: STAppSettings.Import {
            return STAppSettings.current.import
        }
        
        private(set) var lastImportDate: Date? {
            set {
                UserDefaults.standard.set(newValue, forKey: "auotImporter.lastImportDate")
            } get {
                return (UserDefaults.standard.object(forKey: "auotImporter.lastImportDate") as? Date)
            }
        }
        
        //MARK: - Public methods
        
        public init() {
            self.autoImportQueue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 1, underlyingQueue: self.dispatchQueue)
            self.importQueue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 1, underlyingQueue: self.dispatchQueue)
            STAppSettings.current.addObserver(self)
        }
        
        public func startImport() {
            guard !self.isStarted else {
                return
            }
                        
            self.observerEvents.forEach { observer in
                observer.autoImporter(didStart: self)
            }
            self.isStarted = true
            self.deleteImportedFiles { [weak self] in
                self?.startImportAssets()
            }
        }
        
        public func resetImportDate(date: ImportData, startImport: Bool, end: (() -> Void)? = nil) {
            self.cancelImporting { [weak self] in
                self?.lastImportDate = date.date
                if startImport {
                    self?.startImport()
                }
                end?()
            }
        }
        
        public func add(_ listener: IAutoImporterObserver) {
            self.observerEvents.addObject(listener)
        }
        
        public func remove(_ listener: IAutoImporterObserver) {
            self.observerEvents.removeObject(listener)
        }
        
        public func logout() {
            self.resetImportDate(date: .setupDate, startImport: false)
        }
        
        public func cancelImporting(end: (() -> Void)?) {
            if let currentOporation = self.currentOporation {
                self.endImportingCallBack = {
                    end?()
                }
                currentOporation.cancel()
            } else {
                end?()
            }
        }
        
        //MARK: - Private methods
        
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
            self.startNextImport()
        }
        
        private func endImportIng() {
            guard self.isStarted else {
                return
            }
            self.autoImportQueue.cancelAllOperations()
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
            self.observerEvents.forEach { observer in
                observer.autoImporter(didEnd: self)
            }
        }
        
        private func updateDate(date: Date) {
            guard self.canSetDate else {
                return
            }
            if let lastImportDate = self.lastImportDate, date > lastImportDate {
                self.lastImportDate = date
            } else if self.lastImportDate == nil {
                self.lastImportDate = date
            }
        }
        
        private func startNextImport() {
            self.isImporting = true
                        
            let operation = Operation(importQueue: self.importQueue, fromDate: self.lastImportDate, fetchLimit: self.fetchLimit) { [weak self] importCount in
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
            } failure: { [weak self] error in
                self?.endImportIng()
            } progress: { [weak self] progress in
                if let date = progress.userInfo[.dateKey] as? Date {
                    self?.updateDate(date: date)
                }
            }
            self.currentOporation = operation
            operation.didStartRun(with: self.autoImportQueue)
        }
    }
    
}

extension STImporter.AutoImporter: ISettingsObserver {
    
    public var canStartImport: Bool {
        let application = STApplication.shared
        return application.utils.isLogedIn() && application.isFileSystemAvailable && STAppSettings.current.import.isAutoImportEnable && application.isFileSystemAvailable
    }
        
    public func appSettings(didChange settings: STAppSettings, import: STAppSettings.Import) {
        if `import`.isAutoImportEnable {
            self.startImport()
        } else {
            self.endImportIng()
        }
    }
    
}

public extension STImporter.AutoImporter {
    
    enum AutoImporterError: IError {
       
        case cantImportFiles
        case canceled
        case importerIsBusy
        
        public var message: String {
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
        
        typealias Importable = STImporter.GaleryFileAssetImportable
                
        let date: Date?
        let fetchLimit: Int
        let importQueue: STOperationQueue
        private weak var importer: STImporter.GaleryAssetFileImporter?
        private var progress: Progress
        private var isCancel = false
        
        init(importQueue: STOperationQueue, fromDate: Date?, fetchLimit: Int, success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?) {
            self.progress = Progress(totalUnitCount: Int64(fetchLimit))
            self.fetchLimit = fetchLimit
            self.date = fromDate
            self.importQueue = importQueue
            super.init(success: success, failure: failure, progress: progress)
        }
        
        //MARK: - override methods
        
        public override func cancel() {
            guard !self.isCancel else {
                return
            }
            self.isCancel = true
            if let importer = self.importer {
                importer.cancel()
            } else {
                self.responseFailed(error: AutoImporterError.canceled)
            }
        }
        
        public override func resume() {
            super.resume()
            self.canImportFiles { [weak self] canImport in
                if canImport {
                    self?.enumerateObjects()
                } else {
                    self?.responseFailed(error: AutoImporterError.canceled)
                }
            }
        }
        
        //MARK: - Private methods
        
        private func enumerateObjects() {
            var importFiles = [Importable]()
            self.enumerateObjects { asset, index, stop in
                if self.isExpired {
                    stop.pointee = true
                    return
                }
                let importFile = STImporter.GaleryFileAssetImportable(asset: asset)
                importFiles.append(importFile)
            }
            guard !self.isExpired else {
                return
            }
            self.startImport(importFiles: importFiles)
        }
        
        private func startImport(importFiles: [Importable]) {
            
            guard let queue = self.delegate?.underlyingQueue else {
                self.responseFailed(error: AutoImporterError.canceled)
                return
            }
           
            guard !self.isExpired else {
                queue.async { [weak self] in
                    self?.responseFailed(error: AutoImporterError.canceled)
                }
                return
            }
            
            var resultDate = self.date
            var importedAssets = [PHAsset]()
            
            let responseQueue = self.importQueue.underlyingQueue ?? STImporter.importerDispatchQueue
                        
            let importer = STImporter.GaleryFileImporter(importFiles: importFiles, operationQueue: self.importQueue, responseQueue: responseQueue, startHendler: {}, progressHendler: { [weak self] progress in
                                
                queue.async { [weak self] in
                    guard let weakSelf = self else {
                        return
                    }
                    if let asset = progress.importingFile?.asset {
                        importedAssets.append(asset)
                    }
                    let currentFileDate = progress.importingFile?.asset.creationDate
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
                
            }, complition: { [weak self] files, importableFiles in
                func response(count: Int) {
                    queue.async { [weak self] in
                        guard let weakSelf = self else {
                            return
                        }
                        if weakSelf.isCancel {
                            weakSelf.responseFailed(error: AutoImporterError.canceled)
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
                
            }, uploadIfNeeded: true)
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
