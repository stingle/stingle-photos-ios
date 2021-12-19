//
//  STFileAutoImporter.swift
//  Stingle
//
//  Created by Khoren Asatryan on 12/16/21.
//

import Foundation
import Photos

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
        
        private var fetchLimit: Int = 200
        private var isStarted: Bool = false
        
        func startImport() {
            guard !self.isStarted else {
                return
            }
            self.isStarted = true
            self.startImportAssets()
        }
        
        private func startImportAssets() {
            
            self.startNextImport()
        }
        
        
        private func startNextImport() {
            
            
            let operation = Operation(success: { result in
                
                print("")
                
                
            }, failure: { error in
                print("")
                
            }, progress: { error in
                print("")
                
            }, fromDate: self.lastImportDate, fetchLimit: self.fetchLimit)
            
            
            operation.didStartRun(with: self.queue)
            
        }
        
                
    }
    
}

extension STImporter.AuotImporter {
        
    class Operation: STOperation<Any> {
        
        let date: Date?
        let fetchLimit: Int
        private var importer: STImporter.Importer?
        
        init(success: STOperationSuccess?, failure: STOperationFailure?,  progress: STOperationProgress?, fromDate: Date?, fetchLimit: Int) {
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
                let uploadable = STFileUploader.FileUploadable(asset: asset)
                uploadables.append(uploadable)
                
                stop.pointee = true
            }
            self.startImport(uploadables: uploadables)
        }
        
        private func startImport(uploadables: [STFileUploader.FileUploadable]) {
            
            let importer = STApplication.shared.uploader.upload(files: uploadables)
            
            
            importer.progressHendler = { progress in
                print(progress.completedUnitCount)
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
