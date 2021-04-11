//
//  STDataBaseCollectionProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class DataBaseCollectionProvider<Model: ICDConvertable, ManagedModel: IManagedObject, DeleteFile: ILibraryDeleteFile>: DataBaseProvider<Model> {
        
        let dataSources = STObserverEvents<STDataBase.DataSource<Model>>()
                
        override init(container: STDataBaseContainer) {
            super.init(container: container)
        }
        
        //MARK: - Sync insert
        
        func sync(db models: [Model]?, context: NSManagedObjectContext, lastDate: Date) throws -> Date {
            guard let models = models, !models.isEmpty else {
                return lastDate
            }
            let inserts = try self.getInsertObjects(with: models)
            guard inserts.lastDate >= lastDate, !inserts.json.isEmpty else {
                return max(lastDate, inserts.lastDate)
            }
            let insertRequest = NSBatchInsertRequest(entityName: ManagedModel.entityName, objects: inserts.json)
            let _ = try context.execute(insertRequest)
            return inserts.lastDate
        }
               
        func getInsertObjects(with files: [Model]) throws -> (json: [[String : Any]], lastDate: Date) {
            //Implement in chid classes
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        //MARK: - Sync delete
        
        func deleteObjects(_ deleteFiles: [DeleteFile]?, in context: NSManagedObjectContext, lastDate: Date) throws -> Date {
            guard let deleteFiles = deleteFiles, !deleteFiles.isEmpty else {
                return lastDate
            }
            let result = try self.getDeleteObjects(deleteFiles, in: context)
            guard result.date >= lastDate, !result.models.isEmpty else {
                return max(lastDate, result.date)
            }
            
            let objectIDs = result.models.compactMap { (model) -> NSManagedObjectID? in
                return model.objectID
            }
            let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            let _ = try context.execute(deleteRequest)
            return result.date
        }
        
        func getDeleteObjects(_ deleteFiles: [DeleteFile], in context: NSManagedObjectContext) throws -> (models: [ManagedModel], date: Date) {
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        func didStartSync() {
            self.dataSources.forEach { (controller) in
                controller.didStartSync()
            }
        }
        
        func finishSync() {
            self.dataSources.forEach { (controller) in
                controller.reloadData()
                controller.didEndSync()
            }
        }
        
        func reloadData() {
            self.dataSources.forEach { (controller) in
                controller.reloadData()
            }
        }
        
        //MARK: - DataSource
        
        func createDataSource(sortDescriptorsKeys: [String], sectionNameKeyPath: String?) -> DataSource<Model> {
            let dataSource = STDataBase.DataSource<Model>(sortDescriptorsKeys: sortDescriptorsKeys, viewContext: self.container.viewContext, sectionNameKeyPath: sectionNameKeyPath)
            self.dataSources.addObject(dataSource)
            return dataSource
        }
        
        func add(model: ManagedModel.Model) {
            let context = self.container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.undoManager = nil
            context.performAndWait {
                _ = ManagedModel(model: model, context: context)
                self.container.saveContext(context)
                context.reset()
            }
        }
        
    }

}

protocol IProviderDelegate: class {
    
    func didStartSync(dataSource: IProviderDataSource)
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    func didEndSync(dataSource: IProviderDataSource)
    
}

protocol IProviderDataSource: class {
    
    func reloadData()
    func object(for indexPath: IndexPath) -> Any?
    
}

extension STDataBase {
    
    class DataSource<Model: ICDConvertable>: NSObject, NSFetchedResultsControllerDelegate, IProviderDataSource {
        
        let sortDescriptorsKeys: [String]
        let sectionNameKeyPath: String?
        let ascending: Bool
        
        private(set) var snapshotReference: NSDiffableDataSourceSnapshotReference?
        private let viewContext: NSManagedObjectContext
        private var controller: NSFetchedResultsController<Model.ManagedModel>!
        
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
        
        private func createResultsController() -> NSFetchedResultsController<Model.ManagedModel> {
            let filesFetchRequest = NSFetchRequest<Model.ManagedModel>(entityName: Model.ManagedModel.entityName)
            let sortDescriptors = self.sortDescriptorsKeys.compactMap { (key) -> NSSortDescriptor in
                return NSSortDescriptor(key: key, ascending: self.ascending)
            }
            filesFetchRequest.sortDescriptors = sortDescriptors
            let resultsController = NSFetchedResultsController(fetchRequest: filesFetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName: Model.ManagedModel.entityName)
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
            let result = try? Model(model: obj)
            return result
        }
        
        func sectionTitle(at secction: Int) -> String? {
            return self.snapshotReference?.sectionIdentifiers[secction] as? String
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
