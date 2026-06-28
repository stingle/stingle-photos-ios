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

            context.performAndWait {
                do {
                    if let inserts = try? self.getInsertObjects(with: models) {
                        let insertRequest = NSBatchInsertRequest(entityName: ManagedObject.entityName, objects: inserts.json)
                        insertRequest.resultType = .objectIDs
                        let result = try (context.execute(insertRequest) as? NSBatchInsertResult)?.result as? [NSManagedObjectID]
                        if let result = result {
                            ids.append(contentsOf: result)
                        }
                    }
                } catch {
                    STLogger.log(error: error)
                }
            }

            if reloadData {
                // Batch insert bypasses the contexts; merge the new ids into the view context so the
                // gallery FRC emits incremental item inserts (O(changes)) instead of a full re-fetch.
                self.mergeBatchChanges(inserted: ids, deleted: [])
                self.notifyObservers(models: models, changeType: .add)
            }

        }

        public func delete(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            guard !models.isEmpty else {
                return
            }
            let context = context ?? self.container.backgroundContext
            var ids = [NSManagedObjectID]()
            context.performAndWait {
                do {
                    let cdModes = try self.getObjects(by: models, in: context)
                    let objectIDs = cdModes.compactMap { (model) -> NSManagedObjectID? in
                        return model.objectID
                    }
                    let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    let result = try (context.execute(deleteRequest) as? NSBatchDeleteResult)?.result as? [NSManagedObjectID]
                    if let result = result {
                        ids.append(contentsOf: result)
                    }
                } catch {
                }
            }

            if reloadData {
                // Batch delete also bypasses the contexts; merge the removed ids so the FRC emits
                // incremental item deletes.
                self.mergeBatchChanges(inserted: [], deleted: ids)
                self.notifyObservers(models: models, changeType: .delete)
            }

        }

        public func update(models: [Model], reloadData: Bool, context: NSManagedObjectContext? = nil) {
            let context = context ?? self.container.backgroundContext
            context.performAndWait {
                do {
                    let cdModels = try self.getObjects(by: models, in: context)
                    cdModels.forEach { cdbject in
                        if let model = models.first(where: { $0.identifier == cdbject.identifier }) {
                            model.update(model: cdbject)
                        }
                    }

                    if context.hasChanges {
                        // A normal save auto-merges into the view context, which makes the gallery FRC
                        // emit incremental item updates — no batch op / mergeChanges needed here.
                        try context.save()
                    }
                } catch {
                    STLogger.log(error: error)
                }
            }

            if reloadData {
                self.notifyObservers(models: models, changeType: .update)
            }

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
        
        // Merge batch-operation results (which bypass the managed-object contexts) into the view context,
        // so the gallery FRC observing it emits incremental item-level changes. This is what keeps a
        // single add/delete an O(changes) UI update instead of an O(library) `performFetch`.
        private func mergeBatchChanges(inserted: [NSManagedObjectID], deleted: [NSManagedObjectID]) {
            var changes = [AnyHashable: Any]()
            if !inserted.isEmpty {
                changes[NSInsertedObjectsKey] = inserted
            }
            if !deleted.isEmpty {
                changes[NSDeletedObjectsKey] = deleted
            }
            guard !changes.isEmpty else {
                return
            }
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.container.viewContext])
        }

        // Notify the non-FRC observers (storage screen, album/menu, etc.). The FRC-backed collection
        // views update themselves from `mergeBatchChanges` (add/delete) or the save auto-merge (update),
        // so this no longer drives a `performFetch`.
        private func notifyObservers(models: [Model], changeType: DataBaseChangeType) {

            guard !models.isEmpty else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
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

                if STEnvironment.current.appIsExtension {
                    STDarwinNotificationCenter.shared.postNotification(weakSelf.notificationReloadDataProviderAppIsExtension)
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
