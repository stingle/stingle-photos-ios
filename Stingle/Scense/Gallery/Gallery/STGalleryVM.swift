//
//  STGalleryVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Photos
import UIKit
import CoreData
import StingleRoot

class STGalleryVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let uploader = STApplication.shared.uploader
    private let fileWorker = STFileWorker()
    
    func createDBDataSource() -> STDataBase.DataSource<STLibrary.GaleryFile> {
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        let sorting = self.getSorting()
        return galleryProvider.createDataSource(sortDescriptorsKeys: sorting, sectionNameKeyPath: #keyPath(STCDFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
    
    func upload(assets: [PHAsset]) -> STImporter.GaleryAssetFileImporter {
        let files = assets.compactMap({ return STImporter.GaleryFileAssetImportable(asset: $0) })
        let importer = self.uploader.upload(files: files)
        return importer
    }
    
    func getFiles(fileNames: [String]) -> [STLibrary.GaleryFile] {
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        let files = galleryProvider.fetchObjects(fileNames: fileNames)
        return files
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func deleteFile(files: [STLibrary.GaleryFile], completion: @escaping (IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.fileWorker.moveFilesToTrash(files: files, reloadDBData: true)
                completion(nil)
            } catch {
                completion((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func getSorting() -> [STDataBase.DataSource<STLibrary.GaleryFile>.Sort] {
        let dateCreated = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.dateCreated), ascending: nil)
        let dateModified = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.dateModified), ascending: true)
        let file = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.file), ascending: true)
        return [dateCreated, dateModified, file]
    }
    
}

extension STCDFile {

    // `day` is the `sectionNameKeyPath` for the gallery / trash / albumFiles FRCs (all three CD
    // classes inherit STCDFile). It is NOT a stored Core Data attribute, so
    // `NSFetchedResultsController.performFetch()` cannot section in SQLite — it must evaluate `day`
    // for *every* object to build the sections, which faults the whole library and runs a
    // DateFormatter per row, on the MAIN thread, on every reload (incremental sync, and the
    // completion burst at the end of an upload). That O(N) main-thread work was the multi-second
    // "freeze when upload finishes" (and the residual sync hitch). `fetchBatchSize` can't help —
    // section evaluation forces full faulting regardless.
    //
    // Two optimizations, both preserving the exact same section strings:
    //  1. A dedicated formatter whose `dateFormat` is set ONCE. `STDateManager.dateToString`
    //     reassigns `dateFormat` on every call, and reassigning it re-parses the ICU pattern —
    //     pathologically slow when called N times in a tight loop.
    //  2. Memoize the result by `objectID` (`NSCache`: thread-safe + auto-evicting under memory
    //     pressure). `dateCreated` is immutable per file, so a cached value never goes stale. The
    //     getter resolves a cache hit from `objectID` alone — it does NOT touch `dateCreated`, so a
    //     hit does not fault the object. After the gallery's first load warms the cache, later
    //     `performFetch`es (upload completion, incremental sync, the per-file auto-merge) re-section
    //     every existing row straight from the cache without faulting it, so the reload is cheap.
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = STDateManager.DateFormat.mmm_dd_yyyy.rawValue
        return formatter
    }()

    private static let dayCache = NSCache<NSManagedObjectID, NSString>()

    @objc var day: String {
        #if DEBUG
        STCDFile.__dayCalls += 1
        #endif
        let objectID = self.objectID
        // Only memoize rows with a permanent ID (FRC-fetched and batch-inserted rows have one);
        // a temporary ID changes on save, so caching under it would be wasted.
        let isCacheable = !objectID.isTemporaryID
        if isCacheable, let cached = Self.dayCache.object(forKey: objectID) {
            #if DEBUG
            STCDFile.__dayHits += 1
            #endif
            return cached as String
        }
        #if DEBUG
        STCDFile.__dayMiss += 1
        #endif
        guard let dateCreated = self.dateCreated else {
            return ""
        }
        let str = Self.dayFormatter.string(from: dateCreated)
        if isCacheable {
            Self.dayCache.setObject(str as NSString, forKey: objectID)
        }
        return str
    }

}
