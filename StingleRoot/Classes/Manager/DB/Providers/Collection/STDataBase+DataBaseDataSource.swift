//
//  STDataBaseDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import CoreData
import UIKit

// Incremental changes reported by the `NSFetchedResultsController`'s item-level delegate. They are
// applied to the collection view with `performBatchUpdates` (cost = O(number of changes)) instead of
// diffing a full snapshot of the whole library (cost = O(library size)) — which is what lets the
// gallery scale to very large libraries without a multi-second main-thread freeze on every change.
public struct STDataSourceChanges {

    public var insertedSections = IndexSet()
    public var deletedSections = IndexSet()
    public var insertedItems = [IndexPath]()
    public var deletedItems = [IndexPath]()
    public var updatedItems = [IndexPath]()
    public var movedItems = [(from: IndexPath, to: IndexPath)]()

    public var isEmpty: Bool {
        return self.insertedSections.isEmpty && self.deletedSections.isEmpty
            && self.insertedItems.isEmpty && self.deletedItems.isEmpty
            && self.updatedItems.isEmpty && self.movedItems.isEmpty
    }

    public var count: Int {
        return self.insertedSections.count + self.deletedSections.count
            + self.insertedItems.count + self.deletedItems.count
            + self.updatedItems.count + self.movedItems.count
    }

    fileprivate mutating func reset() {
        self = STDataSourceChanges()
    }
}

public protocol IProviderDelegate: AnyObject {
    func didStartSync(dataSource: IProviderDataSource)
    func didEndSync(dataSource: IProviderDataSource)
    // Incremental update: apply only these changes to the UI.
    func dataSource(_ dataSource: IProviderDataSource, didChange changes: STDataSourceChanges)
    // Full reload (initial load, unlock, or a delta too large to apply incrementally): re-read everything.
    func dataSourceDidReloadData(_ dataSource: IProviderDataSource)
}

public extension IProviderDelegate {
    func didStartSync(dataSource: IProviderDataSource) {}
    func didEndSync(dataSource: IProviderDataSource) {}
    func dataSource(_ dataSource: IProviderDataSource, didChange changes: STDataSourceChanges) {}
    func dataSourceDidReloadData(_ dataSource: IProviderDataSource) {}
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

        private var controller: NSFetchedResultsController<ManagedModel>!

        let viewContext: NSManagedObjectContext

        // False until the FRC's first `performFetch`. Every query returns empty before that rather than
        // touching the controller's nil section/object internals (which trap with EXC_BAD_ACCESS — e.g.
        // the file viewer asking for a file's index right after creation).
        private var hasFetched = false
        // Buffers the FRC's item-level deltas across a will/did-change cycle.
        private var pendingChanges = STDataSourceChanges()

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

        //MARK: - Counts / lookups (read straight from the FRC; no snapshot)

        public var numberOfSections: Int {
            guard self.hasFetched else { return .zero }
            return self.controller.sections?.count ?? .zero
        }

        public func numberOfItems(in section: Int) -> Int {
            guard self.hasFetched, let sections = self.controller.sections, section >= .zero, section < sections.count else {
                return .zero
            }
            return sections[section].numberOfObjects
        }

        public var numberOfItems: Int {
            guard self.hasFetched else { return .zero }
            return self.controller.fetchedObjects?.count ?? .zero
        }

        public func object(at indexPath: IndexPath) -> Model? {
            guard !self.isFetching, self.isValid(indexPath: indexPath) else {
                return nil
            }
            let obj = self.controller.object(at: indexPath)
            let result = try? Model(model: obj)
            return result
        }

        public func managedModel(at indexPath: IndexPath) -> ManagedModel? {
            guard !self.isFetching, self.isValid(indexPath: indexPath) else {
                return nil
            }
            return self.controller.object(at: indexPath)
        }

        public func sectionTitle(at secction: Int) -> String? {
            guard self.hasFetched, !self.isFetching, let sections = self.controller.sections, secction >= .zero, secction < sections.count else {
                return nil
            }
            return sections[secction].name
        }

        public func indexPath(forObject object: ManagedModel) -> IndexPath? {
            guard self.hasFetched, !self.isFetching else {
                return nil
            }
            return self.controller.indexPath(forObject: object)
        }

        public func indexPath(forObject model: Model) -> IndexPath? {
            guard self.hasFetched, !self.isFetching, let managedObjectID = model.managedObjectID else {
                return nil
            }
            // Resolve the FRC's own (viewContext) instance for this id, then ask the FRC for its index
            // path. `object(with:)` returns a fault without a round-trip; `indexPath(forObject:)` returns
            // nil if the object isn't in the fetched results (e.g. filtered out), which is correct.
            let object = self.viewContext.object(with: managedObjectID)
            guard let managed = object as? ManagedModel else {
                return nil
            }
            return self.controller.indexPath(forObject: managed)
        }

        private func isValid(indexPath: IndexPath) -> Bool {
            guard self.hasFetched, let sections = self.controller.sections, indexPath.section >= .zero, indexPath.section < sections.count else {
                return false
            }
            return indexPath.item >= .zero && indexPath.item < sections[indexPath.section].numberOfObjects
        }

        //MARK: - IProviderDataSource

        // A `performFetch()` rebuilds the FRC's whole section structure on the MAIN thread — the
        // O(library) path, used only for initial load / unlock / sync / a delta too large to apply
        // incrementally (NOT per add/update/delete — those now arrive as item-level deltas through
        // mergeChanges/auto-merge). It runs synchronously so a caller that immediately reads back (the
        // file viewer asks a tapped file's index in `viewDidLoad`) sees a populated FRC. Callers run on
        // the main queue (the view contexts' queue), as the FRC requires.
        public func reloadData() {
            guard self.canReloadData else {
                return
            }
            self.isFetching = true
            try? self.controller.performFetch()
            self.hasFetched = true
            self.isFetching = false
            self.delegate?.dataSourceDidReloadData(self)
        }

        //MARK: - NSFetchedResultsControllerDelegate (item-level, incremental)

        public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            self.pendingChanges.reset()
        }

        public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
            switch type {
            case .insert:
                self.pendingChanges.insertedSections.insert(sectionIndex)
            case .delete:
                self.pendingChanges.deletedSections.insert(sectionIndex)
            default:
                break
            }
        }

        public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    self.pendingChanges.insertedItems.append(newIndexPath)
                }
            case .delete:
                if let indexPath = indexPath {
                    self.pendingChanges.deletedItems.append(indexPath)
                }
            case .update:
                if let indexPath = indexPath {
                    self.pendingChanges.updatedItems.append(indexPath)
                }
            case .move:
                if let indexPath = indexPath, let newIndexPath = newIndexPath {
                    // Some OS versions report an in-place "update" as a move to the same index path.
                    if indexPath == newIndexPath {
                        self.pendingChanges.updatedItems.append(indexPath)
                    } else {
                        self.pendingChanges.movedItems.append((from: indexPath, to: newIndexPath))
                    }
                }
            @unknown default:
                break
            }
        }

        public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            let changes = self.pendingChanges
            self.pendingChanges.reset()
            guard !changes.isEmpty else {
                return
            }
            self.delegate?.dataSource(self, didChange: changes)
        }

        //MARK: - Private

        private func createResultsController(cacheName: String?) -> NSFetchedResultsController<ManagedModel> {
            let filesFetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
            let sortDescriptors = self.sortDescriptorsKeys.compactMap { (sort) -> NSSortDescriptor in
                return NSSortDescriptor(key: sort.key, ascending: sort.ascending ?? self.ascending)
            }

            filesFetchRequest.predicate = self.predicate
            filesFetchRequest.sortDescriptors = sortDescriptors
            // Fault rows in batches so the initial `performFetch()` (and any full reload) doesn't
            // materialize every object's property values at once. Cells fault their values in as they
            // scroll into view; incremental updates only touch the changed rows.
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
