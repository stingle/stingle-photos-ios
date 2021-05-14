//
//  STDataBaseCollectionProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData
import UIKit

protocol ICollectionProvider: AnyObject {
    
}

protocol ICollectionProviderObserver {
    func dataBaseCollectionProvider(didAdded provider: ICollectionProvider, models: [IDataBaseProviderModel])
    func dataBaseCollectionProvider(didDeleted provider: ICollectionProvider, models: [IDataBaseProviderModel])
    func dataBaseCollectionProvider(didUpdated provider: ICollectionProvider, models: [IDataBaseProviderModel])
}

extension ICollectionProviderObserver {
    
    func dataBaseCollectionProvider(didAdded provider: ICollectionProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseCollectionProvider(didDeleted provider: ICollectionProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseCollectionProvider(didUpdated provider: ICollectionProvider, models: [IDataBaseProviderModel]) {}
    
}

extension STDataBase {
    
    class DataBaseCollectionProvider<ManagedModel: IManagedObject, DeleteFile: ILibraryDeleteFile>: DataBaseProvider<ManagedModel.Model>, ICollectionProvider  {

        typealias Model = ManagedModel.Model
        private let dataSources = STObserverEvents<STDataBase.DataSource<ManagedModel>>()
        private let observerProvider = STObserverEvents<ICollectionProviderObserver>()
                
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
            insertRequest.resultType = .objectIDs
            let resultInset = try context.execute(insertRequest)
            let objectIDs = (resultInset as! NSBatchInsertResult).result as! [NSManagedObjectID]
            try self.syncUpdateModels(objIds: inserts.objIds, insertedObjectIDs: objectIDs, context: context)
            return inserts.lastDate
        }
        
        func syncUpdateModels(objIds: [String: Model], insertedObjectIDs: [NSManagedObjectID], context: NSManagedObjectContext) throws {
            //Implement in chid classes
            throw STDataBase.DataBaseError.dateNotFound
        }
               
        func getInsertObjects(with files: [Model]) throws -> (json: [[String : Any]], objIds: [String: Model], lastDate: Date) {
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
        
        func getObjects(by models: [Model], in context: NSManagedObjectContext) throws -> [ManagedModel] {
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        func updateObjects(by models: [Model], managedModels: [ManagedModel], in context: NSManagedObjectContext) throws {
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
            DispatchQueue.main.async { [weak self] in
                self?.dataSources.forEach { (controller) in
                    controller.reloadData()
                }
            }           
        }
        
        //MARK: - DataSource
        
        func createDataSource(sortDescriptorsKeys: [String], sectionNameKeyPath: String?, predicate: NSPredicate? = nil, cacheName: String? = ManagedModel.entityName) -> DataSource<ManagedModel> {
            let dataSource = STDataBase.DataSource<ManagedModel>(sortDescriptorsKeys: sortDescriptorsKeys, viewContext: self.container.viewContext, predicate: predicate, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
            self.dataSources.addObject(dataSource)
            return dataSource
        }
        
        //MARK: - Methods
        
        func add(models: [Model], reloadData: Bool) {
            let context = self.container.newBackgroundContext()
            context.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
            context.performAndWait {
                do {
                    if let inserts = try? self.getInsertObjects(with: models) {
                        let insertRequest = NSBatchInsertRequest(entityName: ManagedModel.entityName, objects: inserts.json)
                        insertRequest.resultType = .objectIDs
                        let _ = try context.execute(insertRequest)
                    }
                } catch {
                    print(error)
                }
            }
            
            if reloadData {
                self.reloadData()
                self.observerProvider.forEach { observer in
                    observer.dataBaseCollectionProvider(didAdded: self, models: models)
                }
            }
        }
        
        func delete(models: [Model], reloadData: Bool) {
            
            guard !models.isEmpty else {
                return
            }
            
            let context = self.container.newBackgroundContext()
            context.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
            context.performAndWait {
                do {
                    let cdModes = try self.getObjects(by: models, in: context)
                    let objectIDs = cdModes.compactMap { (model) -> NSManagedObjectID? in
                        return model.objectID
                    }
                    let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
                    let _ = try? context.execute(deleteRequest)
                } catch {
                    print("error")
                }
                
            }
            
            if reloadData {
                self.reloadData()
                self.observerProvider.forEach { observer in
                    observer.dataBaseCollectionProvider(didDeleted: self, models: models)
                }
            }
        }
        
        func update(models: [Model], reloadData: Bool) {
            let context = self.container.newBackgroundContext()
            var resultError: Error?
            context.performAndWait {
                do {
                    let cdModel = try self.getObjects(by: models, in: context)
                    try self.updateObjects(by: models, managedModels: cdModel, in: context)
                    if context.hasChanges {
                        try context.save()
                    }
                } catch {
                    resultError = error
                }
                
                if resultError != nil {
                    return
                }
                
                if reloadData {
                    self.reloadData()
                    self.observerProvider.forEach { observer in
                        observer.dataBaseCollectionProvider(didUpdated: self, models: models)
                    }
                }
            }            
        }
        
        //MARK: - Fetch
        
        func fetchObjects(format predicateFormat: String, arguments argList: CVaListPointer) -> [Model] {
            let predicate = NSPredicate(format: predicateFormat, arguments: argList)
            let cdModels: [ManagedModel] = self.fetch(predicate: predicate)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel()  {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetchAllObjects() -> [Model] {
            let cdModels: [ManagedModel] = self.fetch(predicate: nil)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel()  {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetchObjects(predicate: NSPredicate?) -> [Model] {
            let cdModels = self.fetch(predicate: predicate)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel() {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetchObjects(format predicateFormat: String, _ args: CVarArg...) -> [Model] {
            let predicate = NSPredicate(format: predicateFormat, args)
            return self.fetchObjects(predicate: predicate)
        }
                
        func fetch(predicate: NSPredicate?) -> [ManagedModel] {
            let context = self.container.viewContext
            return context.performAndWait { () -> [ManagedModel] in
                let fetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
                fetchRequest.includesSubentities = true
                fetchRequest.includesPropertyValues = true
                fetchRequest.predicate = predicate
                let cdModels = try? context.fetch(fetchRequest)
                return cdModels ?? []
            }
        }
        
        func fetch(identifiers: [String]) -> [ManagedModel] {
            let predicate = NSPredicate(format: "identifier IN %@", identifiers)
            return self.fetch(predicate: predicate)
        }
        
        func fetch(identifiers: [String], context: NSManagedObjectContext) -> [ManagedModel] {
            let predicate = NSPredicate(format: "identifier IN %@", identifiers)
            let fetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
            fetchRequest.predicate = predicate
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }
                
        //MARK: - Additionl
        
        func add(_ observer: ICollectionProviderObserver) {
            self.observerProvider.addObject(observer)
        }
        
        func remove(_ observer: ICollectionProviderObserver) {
            self.observerProvider.removeObject(observer)
        }
        
    }

}
