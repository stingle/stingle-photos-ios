//
//  STDataBaseCollectionProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class CollectionProvider<ManagedModel: IManagedObject>: DataBaseProvider<ManagedModel> {
                
        typealias Model = ManagedModel.Model
        let dataSources = STObserverEvents<STDataBase.DataSource<ManagedModel>>()
        
        func reloadData(models: [Model]? = nil) {
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dataSources.forEach { (controller) in
                    controller.reloadData()
                }
                if let models = models, !models.isEmpty {
                    weakSelf.observerProvider.forEach { observer in
                        observer.dataBaseProvider(didReloaded: weakSelf)
                    }
                }
            }
        }
        
        func getInsertObjects(with files: [Model]) throws -> (json: [[String : Any]], objIds: [String: Model], lastDate: Date) {
            //Implement in chid classes
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        //MARK: - DataSource
        
        func createDataSource(sortDescriptorsKeys: [DataSource<ManagedModel>.Sort], sectionNameKeyPath: String?, predicate: NSPredicate? = nil, cacheName: String? = nil) -> DataSource<ManagedModel> {
            let dataSource = self.generateDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: sectionNameKeyPath, predicate: predicate, cacheName: cacheName)
            return dataSource as! DataSource<ManagedModel>
        }
        
        //MARK: - Methods
        
        func add(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            
            guard !models.isEmpty else {
                return
            }
            
            let context = context ?? self.container.newBackgroundContext()
            var ids = [NSManagedObjectID]()
            context.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
            context.performAndWait {
                do {
                    if let inserts = try? self.getInsertObjects(with: models) {
                        let insertRequest = NSBatchInsertRequest(entityName: ManagedModel.entityName, objects: inserts.json)
                        insertRequest.resultType = .objectIDs
                        let result = try (context.execute(insertRequest) as? NSBatchInsertResult)?.result as? [NSManagedObjectID]
                        if let result = result {
                            ids.append(contentsOf: result)
                        }
                    }
                    
                    if reloadData {
                        self.reloadData(models: models, ids: ids, changeType: .add)
                        self.observerProvider.forEach { observer in
                            observer.dataBaseProvider(didAdded: self, models: models)
                        }
                    }
                    
                } catch {
                    print(error)
                }
            }
           
        }
        
        func delete(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            guard !models.isEmpty else {
                return
            }
            let context = context ?? self.container.newBackgroundContext()
            context.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
            var ids = [NSManagedObjectID]()
            context.performAndWait {
                do {
                    let cdModes = try self.getObjects(by: models, in: context)
                    let objectIDs = cdModes.compactMap { (model) -> NSManagedObjectID? in
                        return model.objectID
                    }
                    let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    let result = try (context.execute(deleteRequest) as? NSBatchUpdateResult)?.result as? [NSManagedObjectID]
                    
                    if let result = result {
                        ids.append(contentsOf: result)
                    }
                    
                    if reloadData {
                        self.reloadData(models: models, ids: ids, changeType: .delete)
                        self.observerProvider.forEach { observer in
                            observer.dataBaseProvider(didDeleted: self, models: models)
                        }
                    }
                    
                } catch {
                }
            }
            
        }
        
        func update(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            let context = context ?? self.container.newBackgroundContext()
            
            context.mergePolicy = NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType
            var ids = [NSManagedObjectID]()
            
            context.performAndWait {
                models.forEach { model in
                    do {
                        let batchRequest = NSBatchUpdateRequest(entityName: ManagedModel.entityName)
                        let predicate = NSPredicate(format: "identifier == %@", model.identifier)
                        batchRequest.resultType = .updatedObjectIDsResultType
                        batchRequest.predicate = predicate
                        batchRequest.propertiesToUpdate = try model.toManagedModelJson()
                        let result = try (context.execute(batchRequest) as? NSBatchUpdateResult)?.result as? [NSManagedObjectID]
                        
                        if let result = result {
                            ids.append(contentsOf: result)
                        }
                        
                    } catch {
                        print(error)
                    }
                }
                
                if reloadData {
                    self.reloadData(models: models, ids: ids, changeType: .update)
                }
                                
            }
            
            
        }
        
        //MARK: - Fetch
        
        func fetchObjects(format predicateFormat: String, arguments argList: CVaListPointer, context: NSManagedObjectContext? = nil) -> [Model] {
            let predicate = NSPredicate(format: predicateFormat, arguments: argList)
            let cdModels: [ManagedModel] = self.fetch(predicate: predicate, context: context)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel()  {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetchAllObjects(context: NSManagedObjectContext? = nil) -> [Model] {
            let cdModels: [ManagedModel] = self.fetch(predicate: nil, context: context)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel()  {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetch(identifiers: [String], context: NSManagedObjectContext? = nil) -> [Model] {
            let predicate = NSPredicate(format: "identifier IN %@", identifiers)
            let cdModels = self.fetch(predicate: predicate, context: context)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel() {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetchObjects(predicate: NSPredicate?, context: NSManagedObjectContext? = nil) -> [Model] {
            let cdModels = self.fetch(predicate: predicate, context: context)
            var results = [Model]()
            for cdModel in cdModels {
                if let model = try? cdModel.createModel() {
                    results.append(model)
                }
            }
            return results
        }
        
        func fetchObjects(format predicateFormat: String, _ args: CVarArg..., context: NSManagedObjectContext? = nil) -> [Model] {
            let predicate = NSPredicate(format: predicateFormat, args)
            return self.fetchObjects(predicate: predicate, context: context)
        }
                
        func fetch(predicate: NSPredicate?, context: NSManagedObjectContext? = nil) -> [ManagedModel] {
            let context = context ?? self.container.viewContext
            return context.performAndWait { () -> [ManagedModel] in
                let fetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
                fetchRequest.includesSubentities = true
                fetchRequest.includesPropertyValues = true
                fetchRequest.predicate = predicate
                let cdModels = try? context.fetch(fetchRequest)
                return cdModels ?? []
            }
        }
        
        func fetch(identifiers: [String], context: NSManagedObjectContext? = nil) -> [ManagedModel] {
            let predicate = NSPredicate(format: "identifier IN %@", identifiers)
            return self.fetch(predicate: predicate, context: context)
        }
        
        func fetch(identifiers: [String], context: NSManagedObjectContext) -> [ManagedModel] {
            let predicate = NSPredicate(format: "identifier IN %@", identifiers)
            let fetchRequest = NSFetchRequest<ManagedModel>(entityName: ManagedModel.entityName)
            fetchRequest.predicate = predicate
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }
        
        func getObjects(by models: [Model], in context: NSManagedObjectContext) throws -> [ManagedModel] {
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        func updateObjects(by models: [Model], managedModels: [ManagedModel], in context: NSManagedObjectContext) throws {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first {
                    let cdModel = keyValue.value.first
                    cdModel?.update(model: model, context: context)
                }
            }
        }

        //MARK: - ICollectionProvider
        
        func generateDataSource(sortDescriptorsKeys: [STDataBase.DataSource<ManagedModel>.Sort], sectionNameKeyPath: String?, predicate: NSPredicate?, cacheName: String?) -> IProviderDataSource {
            let dataSource = STDataBase.DataSource<ManagedModel>(sortDescriptorsKeys: sortDescriptorsKeys, viewContext: self.container.viewContext, predicate: predicate, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
            self.dataSources.addObject(dataSource)
            return dataSource
        }
        
        //MARK: - private
        
        private func reloadData(models: [Model], ids: [NSManagedObjectID], changeType: DataBaseChangeType) {
            DispatchQueue.main.async { [weak self] in
                
                guard let weakSelf = self, !models.isEmpty else {
                    return
                }
                
                weakSelf.dataSources.forEach { (controller) in
                    controller.reloadData(ids: ids, changeType: changeType)
                }
                
                switch changeType {
                case .add:
                    weakSelf.observerProvider.forEach { observer in
                        observer.dataBaseProvider(didAdded: weakSelf, models: models)
                    }
                case .update:
                    weakSelf.observerProvider.forEach { observer in
                        observer.dataBaseProvider(didUpdated: weakSelf, models: models)
                    }
                case .delete:
                    weakSelf.observerProvider.forEach { observer in
                        observer.dataBaseProvider(didDeleted: weakSelf, models: models)
                    }
                }
            }
        }
                
    }
}

extension STDataBase {
    
    class SyncCollectionProvider<ManagedModel: IManagedObject, DeleteFile: ILibraryDeleteFile>: CollectionProvider<ManagedModel> {
        
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
    }
    

}
