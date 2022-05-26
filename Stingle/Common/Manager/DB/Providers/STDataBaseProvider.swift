//
//  IDataBaseProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/21.
//

import CoreData

protocol IDataBaseProviderProvider: AnyObject {
   
}

protocol IDataBaseProviderProviderObserver {
    func dataBaseProvider(didAdded provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel])
    func dataBaseProvider(didDeleted provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel])
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel])
    
    func dataBaseProvider(didReloaded provider: IDataBaseProviderProvider)
}

extension IDataBaseProviderProviderObserver {
    func dataBaseProvider(didAdded provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseProvider(didDeleted provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {}
    func dataBaseProvider(didReloaded provider: IDataBaseProviderProvider) {}
}

extension STDataBase {
    
    class DataBaseProvider<Model: ICDConvertable>: IDataBaseProviderProvider {
        
        typealias ManagedObject = Model.ManagedModel
        private(set) var container: STDataBaseContainer
        
        let observerProvider = STObserverEvents<IDataBaseProviderProviderObserver>()
        
        init(container: STDataBaseContainer) {
            self.container = container
            NSFetchedResultsController<Model.ManagedModel>.deleteCache(withName: nil)
        }
                
        func getAllObjects() -> [Model.ManagedModel] {
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
        
        func deleteAll(completion: ((IError?) -> Void)? = nil) {
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
        
        func add(_ observer: IDataBaseProviderProviderObserver) {
            self.observerProvider.addObject(observer)
        }
        
        func remove(_ observer: IDataBaseProviderProviderObserver) {
            self.observerProvider.removeObject(observer)
        }
               
    }
    
}

