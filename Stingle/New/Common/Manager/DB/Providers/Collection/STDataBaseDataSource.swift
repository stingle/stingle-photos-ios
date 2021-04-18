//
//  STDataBaseDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import CoreData
import UIKit

protocol IProviderDelegate: class {
    
    func didStartSync(dataSource: IProviderDataSource)
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    func didEndSync(dataSource: IProviderDataSource)
    
}

protocol IProviderDataSource: class {
    
    var identifier: String { get }
    func reloadData()
    
}

extension IProviderDataSource {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}

extension STDataBase {
    
    class DataSource<ManagedModel: IManagedObject>: NSObject, NSFetchedResultsControllerDelegate, IProviderDataSource {
                
        typealias Model = ManagedModel.Model
        
        let sortDescriptorsKeys: [String]
        let sectionNameKeyPath: String?
        let ascending: Bool
        
        private(set) var snapshotReference: NSDiffableDataSourceSnapshotReference?
        let viewContext: NSManagedObjectContext
        private var controller: NSFetchedResultsController<ManagedModel>!
        
        var identifier: String {
            return UUID().uuidString
        }
        
        weak var delegate: IProviderDelegate?
        
        init(sortDescriptorsKeys: [String], viewContext: NSManagedObjectContext, sectionNameKeyPath: String?, ascending: Bool = false) {
            self.ascending = ascending
            self.sortDescriptorsKeys = sortDescriptorsKeys
            self.viewContext = viewContext
            self.sectionNameKeyPath = sectionNameKeyPath
            super.init()
            self.controller = self.createResultsController()
        }
        
        //MARK: - private
        
        private func createResultsController() -> NSFetchedResultsController<ManagedModel> {
            let filesFetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
            let sortDescriptors = self.sortDescriptorsKeys.compactMap { (key) -> NSSortDescriptor in
                return NSSortDescriptor(key: key, ascending: self.ascending)
            }
            filesFetchRequest.sortDescriptors = sortDescriptors
            let resultsController = NSFetchedResultsController(fetchRequest: filesFetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName:ManagedModel.entityName)
            resultsController.delegate = self
            return resultsController
        }
        
        func didStartSync() {
            self.delegate?.didStartSync(dataSource: self)
        }
        
        func didEndSync() {
            self.delegate?.didEndSync(dataSource: self)
        }
        
        //MARK: - NSFetchedResultsControllerDelegate
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
            self.snapshotReference = snapshot
            self.delegate?.dataSource(self, didChangeContentWith: snapshot)
        }
        
        func object(at indexPath: IndexPath) -> Model? {
            let obj = self.controller.object(at: indexPath)
            let result = try? obj.createModel()
            return result
        }
        
        func managedModel(at indexPath: IndexPath) -> ManagedModel? {
            let obj = self.controller.object(at: indexPath)
            return obj
        }
        
        func sectionTitle(at secction: Int) -> String? {
            return self.snapshotReference?.sectionIdentifiers[secction] as? String
        }
        
        func indexPath(forObject object: ManagedModel) -> IndexPath? {
            return self.controller.indexPath(forObject: object)
        }
        
        //MARK: - IProviderDataSource
        
        func reloadData() {
            try? self.controller.performFetch()
        }
        
        func object(for indexPath: IndexPath) -> Any? {
            return self.object(at: indexPath)
        }
    }
        
}
