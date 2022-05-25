//
//  STDataBase+SyncProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/10/22.
//

import Foundation
import CoreData

extension STDataBase {
        
    class SyncProvider<Model: ICDSynchConvertable, DeleteFile: ILibraryDeleteFile>: CollectionProvider<Model> where Model.ManagedModel: ISynchManagedObject {
        
        let providerType: SyncProviderType
        
        init(container: STDataBaseContainer, providerType: SyncProviderType) {
            self.providerType = providerType
            super.init(container: container)
        }

        //MARK: - Override methods
        
        override func getInsertObjects(with files: [Model]) throws -> (json: [[String : Any]], models: Set<Model>, objIds: [String : Model], lastDate: Date) {
            
            var lastDate: Date? = nil
            var jsons = [[String : Any]]()
            var objIds = [String: Model]()
            var setModel = Set<Model>()
            
            for file in files {
                if let oldFile = objIds[file.identifier], oldFile > file {
                    continue
                }
                let json = try file.toManagedModelJson()
                jsons.append(json)
                objIds[file.identifier] = file
                let currentLastDate = lastDate ?? file.dateModified
                if currentLastDate <= file.dateModified {
                    lastDate = file.dateModified
                }
                setModel.insert(file)
            }
           
            guard let myLastDate = lastDate else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            return (jsons, setModel, objIds, myLastDate)
        }

        //MARK: - Public methods
        
        func sync(models: [Model]?, lastSyncDate: Date, deleteFile: [DeleteFile]?, lastdDeleteDate: Date, context: NSManagedObjectContext) throws -> (syncInfo: SyncInfo<Model>, lastSynchDate: Date, lastDeletedsDate: Date) {
            let insetrs = try self.sync(db: models, context: context, lastDate: lastSyncDate)
            let deleteObjectsInfo = try self.deleteObjects(deleteFile, in: context, lastDate: lastdDeleteDate)
            let resultSyncInfo = SyncInfo(syncInfo: insetrs.syncInfo, deletes: deleteObjectsInfo.deleteds)
            return (resultSyncInfo, insetrs.lastDate, deleteObjectsInfo.lastDate)
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
        
        //MARK: - Private methods
        
        private func sync(db models: [Model]?, context: NSManagedObjectContext, lastDate: Date) throws -> (lastDate: Date, syncInfo: SyncInfo<Model>) {
           //Test
            guard let models = models, !models.isEmpty else {
                return (lastDate, .empty)
            }
            let inserts = try self.getInsertObjects(with: models)
            guard inserts.lastDate >= lastDate, !inserts.json.isEmpty else {
                return (max(lastDate, inserts.lastDate), .empty)
            }
            let insertRequest = NSBatchInsertRequest(entityName: Model.ManagedModel.entityName, objects: inserts.json)
            insertRequest.resultType = .objectIDs
            
            let resultInset = try context.execute(insertRequest)
            let objectIDs = (resultInset as! NSBatchInsertResult).result as! [NSManagedObjectID]
            
            let syncModels = self.syncUpdateModels(objIds: inserts.objIds, insertedObjectIDs: objectIDs, context: context)
            return (inserts.lastDate, syncModels)
        }
                               
        //MARK: - Sync delete
        
        private func deleteObjects(_ deleteFiles: [DeleteFile]?, in context: NSManagedObjectContext, lastDate: Date) throws -> (lastDate: Date, deleteds: Set<Model>) {
            guard let deleteFiles = deleteFiles, !deleteFiles.isEmpty else {
                return (lastDate, [])
            }
            let result = try self.getDeleteObjects(deleteFiles, in: context)
            guard result.date >= lastDate, !result.models.isEmpty else {
                return (max(lastDate, result.date), [])
            }
            let objectIDs = result.models.compactMap { (model) -> NSManagedObjectID? in
                return model.objectID
            }
            let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            let _ = try context.execute(deleteRequest)
            return (result.date, result.deleteds)
        }

        private func syncUpdateModels(objIds: [String: Model], insertedObjectIDs: [NSManagedObjectID], context: NSManagedObjectContext) -> SyncInfo<Model> {
            
            var updates = Set<Model>()
            var upgrade = Set<Model>()
            var insertedModes = Set<Model>()
            
            for objectID in insertedObjectIDs {
                guard let objectCD = context.object(with: objectID) as? Model.ManagedModel, let identifier = objectCD.identifier, let object = objIds[identifier]  else {
                    continue
                }
                let status = object.diffStatus(with: objectCD)
                switch status {
                case .none:
                    continue
                case .high(let type):
                    switch type {
                    case .update:
                        updates.insert(object)
                    case .upgrade:
                        upgrade.insert(object)
                    }
                    object.update(model: objectCD)
                case .low:
                    object.updateLowMode(model: objectCD)
                case .equal:
                    object.update(model: objectCD)
                    insertedModes.insert(object)
                }
            }
            
            let result = SyncInfo(inserts: insertedModes, updates: updates, upgrade: upgrade, deletes: [])
            return result
        }
        
        private func getDeleteObjects(_ deleteFiles: [DeleteFile], in context: NSManagedObjectContext) throws -> (models: [Model.ManagedModel], deleteds: Set<Model>, date: Date) {
            
            guard !deleteFiles.isEmpty else {
                throw STDataBase.DataBaseError.dateNotFound
            }
            
            let fileNames = deleteFiles.compactMap { (deleteFile) -> String in
                return deleteFile.identifier
            }
            
            var deleteds = Set<Model>()
            
            let fetchRequest = NSFetchRequest<Model.ManagedModel>(entityName: Model.ManagedModel.entityName)
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", fileNames)
            let deleteingCDItems = try context.fetch(fetchRequest)
            var deleteItems = [Model.ManagedModel]()
            
            let groupCDItems = Set<Model.ManagedModel>(deleteingCDItems)
            let defaultDate =  Date.defaultDate
            var lastDate = defaultDate
            
            for delete in deleteFiles {
                lastDate = max(delete.date, lastDate)
                if let deliteCDObject = groupCDItems.first(where: { $0.identifier == delete.identifier && $0.dateModified ?? defaultDate <= delete.date }) {
                    deleteItems.append(deliteCDObject)
                    let model = try Model(model: deliteCDObject)
                    deleteds.insert(model)
                }
   
            }
            return (deleteItems, deleteds, lastDate)
        }
        
    }
                
}

extension STDataBase.SyncProvider where Model.ManagedModel: STCDFile  {
    
    func fetchObjects(fileNames: [String], context: NSManagedObjectContext? = nil) -> [Model] {
        let predicate = NSPredicate(format: "\(#keyPath(STCDFile.file)) IN %@", fileNames)
        return self.fetchObjects(predicate: predicate, context: context)
    }
    
    func getLocalFiles() -> [Model] {
        let isRemote = NSPredicate(format: "\(#keyPath(STCDFile.isRemote)) == false")
        let isSynched = NSPredicate(format: "\(#keyPath(STCDFile.isSynched)) == false")
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [isRemote, isSynched])
        return self.fetchObjects(predicate: predicate)
    }
    
}
        
