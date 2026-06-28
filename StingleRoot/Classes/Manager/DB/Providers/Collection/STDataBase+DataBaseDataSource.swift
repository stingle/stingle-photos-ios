//
//  STDataBaseDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import CoreData
import UIKit

public protocol IProviderDelegate: AnyObject {
    func didStartSync(dataSource: IProviderDataSource)
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    func didEndSync(dataSource: IProviderDataSource)
}

public extension IProviderDelegate {
    func didStartSync(dataSource: IProviderDataSource) {}
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {}
    func didEndSync(dataSource: IProviderDataSource) {}
}

public protocol IProviderDataSource: AnyObject {
    var identifier: String { get }
    var delegate: IProviderDelegate? { get set }
    func reloadData()
}

public extension IProviderDataSource {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}

public extension STDataBase {
    
    class DataSource<Model: ICDConvertable>: NSObject, NSFetchedResultsControllerDelegate, IProviderDataSource {
                        
        public typealias ManagedModel = Model.ManagedModel
        
        weak public var delegate: IProviderDelegate?
        public let sortDescriptorsKeys: [Sort]
        public let sectionNameKeyPath: String?
        public let ascending: Bool
        public let predicate: NSPredicate?
        public private(set) var isFetching = false
        
        private(set) var snapshotReference: NSDiffableDataSourceSnapshotReference?
        private var controller: NSFetchedResultsController<ManagedModel>!
        
        let viewContext: NSManagedObjectContext
                
        private var invalidIds = [NSManagedObjectID]()
        // Set while a coalesced `performFetch` is already queued for the next run-loop turn (see
        // `scheduleReload`), so a burst of reload requests collapses into a single fetch.
        private var reloadScheduled = false

        var isSyncing: Bool {
            return STApplication.shared.syncManager.isSyncing
        }
        
        public var canReloadData: Bool {
            return STApplication.shared.appLockUnlocker.state == .unlocked
        }
        
        public var identifier: String {
            return UUID().uuidString
        }
                
        public init(sortDescriptorsKeys: [Sort], viewContext: NSManagedObjectContext, predicate: NSPredicate? = nil, sectionNameKeyPath: String?, ascending: Bool = false, cacheName: String? = ManagedModel.entityName) {
            self.ascending = ascending
            self.sortDescriptorsKeys = sortDescriptorsKeys
            self.viewContext = viewContext
            self.sectionNameKeyPath = sectionNameKeyPath
            self.predicate = predicate
            super.init()
            self.controller = self.createResultsController(cacheName: cacheName)
        }
                
        public func didStartSync() {
            self.delegate?.didStartSync(dataSource: self)
        }
        
        public func didEndSync() {
            self.delegate?.didEndSync(dataSource: self)
        }
                
        public func object(at indexPath: IndexPath) -> Model? {
            guard !self.isFetching else {
                return nil
            }
            let obj = self.controller.object(at: indexPath)
            let result = try? Model(model: obj)
            return result
        }
        
        public func managedModel(at indexPath: IndexPath) -> ManagedModel? {
            guard !self.isFetching else {
                return nil
            }
            let obj = self.controller.object(at: indexPath)
            return obj
        }
        
        public func sectionTitle(at secction: Int) -> String? {
            guard !self.isFetching else {
                return nil
            }
            return self.snapshotReference?.sectionIdentifiers[secction] as? String
        }
        
        public func indexPath(forObject object: ManagedModel) -> IndexPath? {
            guard !self.isFetching else {
                return nil
            }
            return self.controller.indexPath(forObject: object)
        }
        
        public func indexPath(forObject model: Model) -> IndexPath? {
            guard let managedObjectID = model.managedObjectID else {
                return nil
            }
            guard let sectionIdentifier = self.snapshotReference?.sectionIdentifier(forSectionContainingItemIdentifier: managedObjectID), let itemIdentifiersInSection = self.snapshotReference?.itemIdentifiersInSection(withIdentifier: sectionIdentifier), let row = itemIdentifiersInSection.firstIndex(where: { $0 as? NSObject == managedObjectID }), let section = self.snapshotReference?.index(ofSectionIdentifier: sectionIdentifier) else {
                return nil
            }
            return IndexPath(row: row, section: section)
        }
        
        //MARK: - IProviderDataSource
        
        public func reloadData() {
            self.scheduleReload()
        }

        public func reloadData(ids: [NSManagedObjectID], changeType: DataBaseChangeType) {
            self.invalidIds.append(contentsOf: ids)
            self.scheduleReload()
        }

        // A `performFetch()` on the gallery FRC re-builds a full-catalog diffable snapshot (O(library),
        // ~0.4-0.5s on a large library) on the MAIN thread. During an import/upload burst the providers
        // request several reloads in quick succession (an import `add`, the post-upload sync
        // re-processing the same files via `finishSync`, etc.), each of which ran its own back-to-back
        // performFetch. Since performFetch always reflects the *current committed store*, collapsing a
        // burst of requests into a single fetch on the next run-loop turn loses nothing — the one fetch
        // sees every change. Accumulated `invalidIds` (the force-reload set) is preserved across the
        // coalesced calls and consumed by the single resulting `didChangeContentWith`.
        private func scheduleReload() {
            guard self.canReloadData else {
                return
            }
            guard !self.reloadScheduled else {
                return
            }
            self.reloadScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.reloadScheduled = false
                guard self.canReloadData else { return }
                self.isFetching = true
                #if DEBUG
                let __t0 = CFAbsoluteTimeGetCurrent()
                let __d0 = STCDFile.__dayCalls, __h0 = STCDFile.__dayHits, __m0 = STCDFile.__dayMiss
                #endif
                try? self.controller.performFetch()
                #if DEBUG
                NSLog("[STPERF] coalesced performFetch entity=%@ took %.3fs | dayCalls=%d hits=%d miss=%d", ManagedModel.entityName, CFAbsoluteTimeGetCurrent() - __t0, STCDFile.__dayCalls - __d0, STCDFile.__dayHits - __h0, STCDFile.__dayMiss - __m0)
                #endif
            }
        }
        
        //MARK: - NSFetchedResultsControllerDelegate
        
        public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
            #if DEBUG
            let __t0 = CFAbsoluteTimeGetCurrent()
            let __items = snapshot.numberOfItems
            let __sections = snapshot.numberOfSections
            let __d0 = STCDFile.__dayCalls
            defer {
                NSLog("[STPERF] didChangeContentWith entity=%@ items=%d sections=%d took %.3fs | dayCalls(cum)=%d Δ=%d", ManagedModel.entityName, __items, __sections, CFAbsoluteTimeGetCurrent() - __t0, STCDFile.__dayCalls, STCDFile.__dayCalls - __d0)
            }
            #endif
            if self.snapshotReference == snapshot {
                self.invalidIds = invalidIds.filter({ element in
                    if #available(iOS 15.0, *) {
                        let isReloaded = snapshot.reloadedItemIdentifiers.first(where: { element == $0 as? NSManagedObjectID }) != nil
                        if isReloaded {
                            return false
                        }
                    }
                    return snapshot.itemIdentifiers.first(where: { element == $0 as? NSManagedObjectID }) != nil
                })
                snapshot.reloadItems(withIdentifiers: invalidIds)
            }
            self.invalidIds.removeAll()
            self.snapshotReference = snapshot
            self.isFetching = false
            self.delegate?.dataSource(self, didChangeContentWith: snapshot)
        }
        
        //MARK: - Private
        
        private func createResultsController(cacheName: String?) -> NSFetchedResultsController<ManagedModel> {
            let filesFetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
            let sortDescriptors = self.sortDescriptorsKeys.compactMap { (sort) -> NSSortDescriptor in
                return NSSortDescriptor(key: sort.key, ascending: sort.ascending ?? self.ascending)
            }
            
            filesFetchRequest.predicate = self.predicate
            filesFetchRequest.sortDescriptors = sortDescriptors
            // Fault rows in batches. `performFetch()` runs on the viewContext (MAIN thread) on every
            // sync (finishSync -> reloadData -> performFetch); without a batch size it materializes
            // every object's property values at once, blocking the UI for seconds on a large library.
            // The diffable snapshot only needs object IDs, and cells fault their values in as they
            // scroll into view, so batching makes the post-sync reload cheap.
            filesFetchRequest.fetchBatchSize = 80
            let resultsController = NSFetchedResultsController(fetchRequest: filesFetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName: cacheName)
            resultsController.delegate = self
            return resultsController
        }
                        
    }
        
}

extension STDataBase.DataSource {
    
    public struct Sort {
       
        public let key: String
        public let ascending: Bool?
        
        public init(key: String, ascending: Bool? = nil) {
            self.key = key
            self.ascending = ascending
        }
        
        public func create(key: String, ascending: Bool? = nil) -> Sort {
            return Sort(key: key, ascending: ascending)
        }
        
    }
    
}
