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
        
        public let sortDescriptorsKeys: [Sort]
        public let sectionNameKeyPath: String?
        public let ascending: Bool
        public let predicate: NSPredicate?
        public private(set) var isFetching = false
        
        private(set) var snapshotReference: NSDiffableDataSourceSnapshotReference?
        let viewContext: NSManagedObjectContext
        private var controller: NSFetchedResultsController<ManagedModel>!
        
        private var invalidIds: [NSManagedObjectID]?
        
        var isSyncing: Bool {
            return STApplication.shared.syncManager.isSyncing
        }
        
        public var identifier: String {
            return UUID().uuidString
        }
        
        weak public var delegate: IProviderDelegate?
        
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
            self.isFetching = true
            self.invalidIds = nil
            try? self.controller.performFetch()
        }
        
        public func reloadData(ids: [NSManagedObjectID], changeType: DataBaseChangeType) {
            self.isFetching = true
            self.invalidIds = ids
            try? self.controller.performFetch()
        }
        
        //MARK: - NSFetchedResultsControllerDelegate
        
        public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
            if self.snapshotReference == snapshot, var invalidIds = self.invalidIds {
                invalidIds = invalidIds.filter({ element in
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
            self.invalidIds = nil
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
