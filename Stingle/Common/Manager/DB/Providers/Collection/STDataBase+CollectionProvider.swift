//
//  STDataBaseCollectionProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class CollectionProvider<Model: ICDConvertable>: DataBaseProvider<Model> {
                
        typealias ManagedObject = Model.ManagedModel
        typealias Model = Model
        
        let dataSources = STObserverEvents<STDataBase.DataSource<Model>>()
        
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
        
        func getInsertObjects(with files: [Model]) throws -> (json: [[String : Any]], models: Set<Model>, objIds: [String: Model], lastDate: Date) {
            //Implement in chid classes
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        func getObjects(by models: [Model], in context: NSManagedObjectContext) throws -> [ManagedObject] {
            guard !models.isEmpty else {
                return []
            }
            let userIds = models.compactMap({ $0.identifier })
            let fetchRequest = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", userIds)
            let deleteingCDItems = try context.fetch(fetchRequest)
            return deleteingCDItems
        }
        
        func updateObjects(by models: [Model], managedModels: [ManagedObject], in context: NSManagedObjectContext) throws {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first, let cdModel = keyValue.value.first {
                    model.update(model: cdModel)
                }
            }
        }
                
        //MARK: - DataSource
        
        func createDataSource(sortDescriptorsKeys: [DataSource<Model>.Sort], sectionNameKeyPath: String?, predicate: NSPredicate? = nil, cacheName: String? = nil) -> DataSource<Model> {
            let dataSource = self.generateDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: sectionNameKeyPath, predicate: predicate, cacheName: cacheName)
            return dataSource as! DataSource<Model>
        }
        
        //MARK: - Methods
        
        func add(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            
            guard !models.isEmpty else {
                return
            }
            
            let context = context ?? self.container.backgroundContext
            var ids = [NSManagedObjectID]()
            
            context.performAndWait { [weak self] in
                guard let weakSelf = self else { return  }
                
                do {
                    if let inserts = try? weakSelf.getInsertObjects(with: models) {
                        let insertRequest = NSBatchInsertRequest(entityName: ManagedObject.entityName, objects: inserts.json)
                        
                        insertRequest.resultType = .objectIDs
                        let result = try (context.execute(insertRequest) as? NSBatchInsertResult)?.result as? [NSManagedObjectID]
                        if let result = result {
                            ids.append(contentsOf: result)
                        }
                    }
                    if reloadData {
                        weakSelf.reloadData(models: models, ids: ids, changeType: .add)
                    }
                    
                } catch {
                    STLogger.log(error: error)
                }
            }
           
        }
        
        func delete(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            guard !models.isEmpty else {
                return
            }
            let context = context ?? self.container.backgroundContext
            var ids = [NSManagedObjectID]()
            context.performAndWait { [weak self] in
                
                guard let weakSelf = self else { return  }
                
                do {
                    let cdModes = try weakSelf.getObjects(by: models, in: context)
                    let objectIDs = cdModes.compactMap { (model) -> NSManagedObjectID? in
                        return model.objectID
                    }
                    let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    let result = try (context.execute(deleteRequest) as? NSBatchDeleteResult)?.result as? [NSManagedObjectID]
                    
                    if let result = result {
                        ids.append(contentsOf: result)
                    }
                    
                    if reloadData {
                        weakSelf.reloadData(models: models, ids: ids, changeType: .delete)
                    }
                    
                } catch {
                }
            }
            
        }
        
        func update(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            let context = context ?? self.container.backgroundContext
            var ids = [NSManagedObjectID]()
            context.performAndWait {[weak self] in
                guard let weakSelf = self else { return }
                do {
                    let cdModels = try weakSelf.getObjects(by: models, in: context)
                    cdModels.forEach { cdbject in
                        if let model = models.first(where: { $0.identifier == cdbject.identifier }) {
                            model.update(model: cdbject)
                            ids.append(cdbject.objectID)
                        }
                    }
                    
                    if context.hasChanges {
                        try context.save()
                    }
                    
                    if reloadData {
                        weakSelf.reloadData(models: models, ids: ids, changeType: .update)
                    }
                    
                } catch {
                    STLogger.log(error: error)
                }
                
            }
            
        }
        

        //MARK: - ICollectionProvider
        
        func generateDataSource(sortDescriptorsKeys: [STDataBase.DataSource<Model>.Sort], sectionNameKeyPath: String?, predicate: NSPredicate?, cacheName: String?) -> IProviderDataSource {
            let dataSource = STDataBase.DataSource<Model>(sortDescriptorsKeys: sortDescriptorsKeys, viewContext: self.container.viewContext, predicate: predicate, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
            self.dataSources.addObject(dataSource)
            return dataSource
        }
        
        //MARK: - private
        
        private func reloadData(models: [Model], ids: [NSManagedObjectID], changeType: DataBaseChangeType) {
            
            guard !ids.isEmpty else {
                return
            }
            
            self.dataSources.forEach { (controller) in
                DispatchQueue.main.async {
                    controller.reloadData(ids: ids, changeType: changeType)
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self, !models.isEmpty else {
                    return
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

extension STDataBase.CollectionProvider {
    
    func fetch(predicate: NSPredicate?, context: NSManagedObjectContext? = nil) -> [ManagedObject] {
        let context = context ?? self.container.backgroundContext
        return context.performAndWait { () -> [ManagedObject] in
            let fetchRequest = NSFetchRequest<ManagedObject>(entityName: Model.ManagedModel.entityName)
            fetchRequest.includesSubentities = true
            fetchRequest.includesPropertyValues = true
            fetchRequest.predicate = predicate
            let cdModels = try? context.fetch(fetchRequest)
            return cdModels ?? []
        }
    }

    func fetch(identifiers: [String], context: NSManagedObjectContext? = nil) -> [ManagedObject] {
        let predicate = NSPredicate(format: "identifier IN %@", identifiers)
        return self.fetch(predicate: predicate, context: context)
    }
    
    func fetch(identifiers: Set<String>, context: NSManagedObjectContext? = nil) -> [ManagedObject] {
        let predicate = NSPredicate(format: "identifier IN %@", identifiers)
        return self.fetch(predicate: predicate, context: context)
    }
        
}

extension STDataBase.CollectionProvider {
    
    func fetchObjects(predicate: NSPredicate? = nil, context: NSManagedObjectContext? = nil) -> [Model] {
        let cdModels: [ManagedObject] = self.fetch(predicate: predicate)
        return cdModels.compactMap({ try? Model(model: $0) })
    }
    
    func fetchObjects(identifiers: [String], context: NSManagedObjectContext? = nil) -> [Model] {
        let predicate = NSPredicate(format: "identifier IN %@", identifiers)
        return self.fetchObjects(predicate: predicate, context: context)
    }
    
}
