//
//  IDataBaseProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/21.
//

import CoreData

public protocol IDataBaseProviderProvider: AnyObject {
   
}

public protocol IDataBaseProviderProviderObserver {
    func dataBaseProvider(didAdded provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel])
    func dataBaseProvider(didDeleted provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel])
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel])
    
    func dataBaseProvider(didReloaded provider: IDataBaseProviderProvider)
}

public extension IDataBaseProviderProviderObserver {
    func dataBaseProvider(didAdded provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseProvider(didDeleted provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseProvider(didReloaded provider: IDataBaseProviderProvider) {}
}

public extension STDataBase {
    
    class DataBaseProvider<Model: ICDConvertable>: IDataBaseProviderProvider {
        
        public typealias ManagedObject = Model.ManagedModel
        private(set) var container: STDataBaseContainer
        
        let observerProvider = STObserverEvents<IDataBaseProviderProviderObserver>()
        
        public init(container: STDataBaseContainer) {
            self.container = container
            NSFetchedResultsController<Model.ManagedModel>.deleteCache(withName: nil)
        }
                
        public func getAllObjects() -> [Model.ManagedModel] {
            let context = self.container.viewContext
            let fetchRequest = NSFetchRequest<Model.ManagedModel>(entityName: Model.ManagedModel.entityName)
            fetchRequest.includesSubentities = false
            do {
                let result = try context.fetch(fetchRequest)
                return result
            } catch {
                return []
            }
        }
        
        public func deleteAll(completion: ((IError?) -> Void)? = nil) {
            let taskContext = self.container.viewContext
            taskContext.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedObject.entityName)
                            
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    let _ = try taskContext.execute(batchDeleteRequest)
                    completion?(nil)
                } catch  {
                    completion?(DataBaseError.error(error: error))
                }
            }
        }
        
        public func add(_ observer: IDataBaseProviderProviderObserver) {
            self.observerProvider.addObject(observer)
        }
        
        public func remove(_ observer: IDataBaseProviderProviderObserver) {
            self.observerProvider.removeObject(observer)
        }
               
    }
    
}

