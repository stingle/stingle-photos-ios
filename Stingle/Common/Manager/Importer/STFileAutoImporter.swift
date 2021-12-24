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
        
        private let dispatchQueue = DispatchQueue(label: "AuotImporter.queue", attributes: .concurrent)
        
        lazy private var queue: STOperationQueue = {
            return STOperationManager.shared.createQueue(maxConcurrentOperationCount: 1, underlyingQueue: self.dispatchQueue)
        }()
        
        private var lastImportDate: Date? {
            set {
                UserDefaults.standard.set(newValue, forKey: "lastImportDate")
            } get {
                return UserDefaults.standard.object(forKey: "lastImportDate") as? Date
            }
        }
        
        private var fetchLimit: Int = 1
        private var isStarted: Bool = false
        
        func startImport() {
            guard !self.isStarted else {
                return
            }
            self.isStarted = true
            self.startImportAssets()
        }
        
        private func startImportAssets() {
            self.lastImportDate = nil
            self.startNextImport()
        }
        
        private func startNextImport() {
            
            print("startNextImport")
            
            let operation = Operation(success: { [weak self] importCount in

                print("startNextImport ended")
                if importCount != .zero {
                    
                    self?.dispatchQueue.asyncAfter(wallDeadline: .now()) { [weak self] in
                        self?.startNextImport()
                    }
                    
                    
                } else {
                    print("startNextImport ended endedendedendedendedended")
                }
                
            }, failure: { error in
                
                print("startNextImport error", error.message)
                
            }, progress: { [weak self] progress in
                if let date = progress.userInfo[.dateKey] as? Date {
                    self?.lastImportDate = date
                }
            }, fromDate: self.lastImportDate, fetchLimit: self.fetchLimit)
            
            
            operation.didStartRun(with: self.queue)
            
        }
        
                
    }
    
}

extension STImporter.AuotImporter {
            
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
        
        override func resume() {
            super.resume()
            self.enumerateObjects()
        }
        
        private func enumerateObjects() {
            var uploadables = [STFileUploader.FileUploadable]()
            self.enumerateObjects { asset, index, stop in
                if self.isExpired {
                    stop.pointee = true
                    return
                }
                let uploadable = STFileUploader.FileUploadable(asset: asset)
                uploadables.append(uploadable)
            }
            guard !self.isExpired else {
                return
            }
            self.startImport(uploadables: uploadables)
        }
        
        private func startImport(uploadables: [STFileUploader.FileUploadable]) {

            guard let queue = self.delegate?.underlyingQueue else {
                self.responseFailed(error: STError.canceled)
                return
            }
            
            let importer = STApplication.shared.uploader.upload(files: uploadables)
            var resultDate = self.date
                        
            importer.progressHendler = { [weak self] progress in
                
                queue.async {
                    guard let self = self else {
                        return
                    }
                                        
                    let currentFileDate = (progress.uploadFile as? STFileUploader.FileUploadable)?.asset.creationDate
                    
                    if let date = resultDate {
                        let fileDate: Date = currentFileDate ?? date
                        resultDate = max(date, fileDate)
                    } else {
                        resultDate = currentFileDate
                    }
                    
                    self.progress.setUserInfoObject(resultDate, forKey: ProgressUserInfoKey.dateKey)
                    self.progress.completedUnitCount = Int64(progress.completedUnitCount)
                    self.responseProgress(result: self.progress)
                }
                
            }
            
            importer.complition = { [weak self] files in
                guard let self = self else {
                    return
                }
                self.responseSucces(result: files.count)
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
        
    }
    
}

fileprivate extension ProgressUserInfoKey {
    
    static var dateKey: ProgressUserInfoKey {
        return ProgressUserInfoKey(rawValue: "date")
    }
    
}
