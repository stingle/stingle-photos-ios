//
//  STDataBaseCollectionProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData
import UIKit

public extension STDataBase {
    
    class CollectionProvider<Model: ICDConvertable>: DataBaseProvider<Model> {
        
        let notificationReloadDataProviderAppIsExtension = STDarwinNotification.Name("notificationReloadDataProviderAppIsExtension")
                        
        public typealias ManagedObject = Model.ManagedModel
        public typealias Model = Model
        let dataSources = STObserverEvents<STDataBase.DataSource<Model>>()
        
        public override init(container: STDataBaseContainer) {
            super.init(container: container)
            self.addReloadDataNotification()
        }
        
        public func reloadData(models: [Model]? = nil) {
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
        
        public func getInsertObjects(with files: [Model]) throws -> (json: [[String : Any]], models: Set<Model>, objIds: [String: Model], lastDate: Date) {
            //Implement in chid classes
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        public func getObjects(by models: [Model], in context: NSManagedObjectContext) throws -> [ManagedObject] {
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
        
        public func updateObjects(by models: [Model], managedModels: [ManagedObject], in context: NSManagedObjectContext) throws {
            let modelsGroup = Dictionary(grouping: models, by: { $0.identifier })
            let managedGroup = Dictionary(grouping: managedModels, by: { $0.identifier })
            managedGroup.forEach { (keyValue) in
                if let key = keyValue.key, let model = modelsGroup[key]?.first, let cdModel = keyValue.value.first {
                    model.update(model: cdModel)
                }
            }
        }
                
        //MARK: - DataSource
        
        public func createDataSource(sortDescriptorsKeys: [DataSource<Model>.Sort], sectionNameKeyPath: String?, predicate: NSPredicate? = nil, cacheName: String? = nil) -> DataSource<Model> {
            let dataSource = self.generateDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: sectionNameKeyPath, predicate: predicate, cacheName: cacheName)
            return dataSource as! DataSource<Model>
        }
        
        //MARK: - Methods
        
        public func add(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            
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
                        #if DEBUG
                        let __ts = CFAbsoluteTimeGetCurrent()
                        #endif
                        let result = try (context.execute(insertRequest) as? NSBatchInsertResult)?.result as? [NSManagedObjectID]
                        #if DEBUG
                        let __dt = CFAbsoluteTimeGetCurrent() - __ts
                        if __dt > 0.1 { NSLog("[STPERF] CollectionProvider.add BATCH-INSERT took %.3fs entity=%@ count=%d", __dt, ManagedObject.entityName, models.count) }
                        #endif
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
        
        public func delete(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
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
                    #if DEBUG
                    let __ts = CFAbsoluteTimeGetCurrent()
                    #endif
                    let result = try (context.execute(deleteRequest) as? NSBatchDeleteResult)?.result as? [NSManagedObjectID]
                    #if DEBUG
                    let __dt = CFAbsoluteTimeGetCurrent() - __ts
                    if __dt > 0.1 { NSLog("[STPERF] CollectionProvider.delete BATCH-DELETE took %.3fs entity=%@ count=%d", __dt, ManagedObject.entityName, objectIDs.count) }
                    #endif
                    
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
        
        public func update(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            let context = context ?? self.container.backgroundContext
            var ids = [NSManagedObjectID]()
            #if DEBUG
            let __tCall = CFAbsoluteTimeGetCurrent()
            #endif
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
                        #if DEBUG
                        let __tSave = CFAbsoluteTimeGetCurrent()
                        #endif
                        try context.save()
                        #if DEBUG
                        let __dtSave = CFAbsoluteTimeGetCurrent() - __tSave
                        if __dtSave > 0.1 { NSLog("[STPERF] CollectionProvider.update CONTEXT.SAVE took %.3fs entity=%@ count=%d", __dtSave, ManagedObject.entityName, models.count) }
                        #endif
                    }

                    if reloadData {
                        weakSelf.reloadData(models: models, ids: ids, changeType: .update)
                    }

                } catch {
                    STLogger.log(error: error)
                }

            }
            #if DEBUG
            let __dtCall = CFAbsoluteTimeGetCurrent() - __tCall
            if __dtCall > 0.1 { NSLog("[STPERF] CollectionProvider.update TOTAL (incl performAndWait wait) took %.3fs entity=%@ count=%d", __dtCall, ManagedObject.entityName, models.count) }
            #endif
            
        }
        

        //MARK: - ICollectionProvider
        
        public func generateDataSource(sortDescriptorsKeys: [STDataBase.DataSource<Model>.Sort], sectionNameKeyPath: String?, predicate: NSPredicate?, cacheName: String?) -> IProviderDataSource {
            let dataSource = STDataBase.DataSource<Model>(sortDescriptorsKeys: sortDescriptorsKeys, viewContext: self.container.viewContext, predicate: predicate, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
            self.dataSources.addObject(dataSource)
            return dataSource
        }
        
        //MARK: - private
        
        private func addReloadDataNotification() {
            STDarwinNotificationCenter.shared.addObserver(self, for: self.notificationReloadDataProviderAppIsExtension) { [weak self] _ in
                guard !STEnvironment.current.appIsExtension else {
                    return
                }
                self?.reloadData()
            }
        }
        
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
                
                if STEnvironment.current.appIsExtension, let name = self?.notificationReloadDataProviderAppIsExtension  {
                    STDarwinNotificationCenter.shared.postNotification(name)
                }
            }
        }
        
        deinit {
            STDarwinNotificationCenter.shared.removeObserver(self)
        }
                
    }
}

public extension STDataBase.CollectionProvider {
    
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

public extension STDataBase.CollectionProvider {
    
    func fetchObjects(predicate: NSPredicate? = nil, batchSize: Int = .zero, context: NSManagedObjectContext? = nil) -> [Model] {
        let context = context ?? self.container.backgroundContext
        return context.performAndWait { () -> [Model] in
            let fetchRequest = NSFetchRequest<ManagedObject>(entityName: ManagedObject.entityName)
            fetchRequest.includesSubentities = true
            fetchRequest.includesPropertyValues = true
            // `batchSize > 0` faults rows in chunks instead of materializing the whole result set at
            // once, so a large scan can't hold the persistent-store lock long enough to stall the
            // main thread.
            fetchRequest.fetchBatchSize = batchSize
            fetchRequest.predicate = predicate
            let cdModels = (try? context.fetch(fetchRequest)) ?? []
            // Build the plain models *inside* the context's queue: `Model(model:)` reads managed-object
            // properties, which is only safe on the owning context's queue. The previous version did
            // this after the fetch returned, on the caller's thread — a Core Data threading violation
            // that also contended with the main-thread gallery merge and froze the UI on big scans.
            return cdModels.compactMap({ try? Model(model: $0) })
        }
    }

    func fetchObjects(identifiers: [String], context: NSManagedObjectContext? = nil) -> [Model] {
        let predicate = NSPredicate(format: "identifier IN %@", identifiers)
        return self.fetchObjects(predicate: predicate, context: context)
    }
    
}
