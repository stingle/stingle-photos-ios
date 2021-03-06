//
//  IDataBaseProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/21.
//

import CoreData

extension STDataBase {
    
    class DataBaseProvider<Model: ICDConvertable> {
        
        private(set) var container: STDataBaseContainer
        
        init(container: STDataBaseContainer) {
            self.container = container
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
            let taskContext = self.container.newBackgroundContext()
            taskContext.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Model.ManagedModel.entityName)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchDeleteRequest.resultType = .resultTypeCount
                do {
                    let _ = try taskContext.execute(batchDeleteRequest)
                    completion?(nil)
                } catch  {
                    completion?(DataBaseError.error(error: error))
                }
            }
        }
               
    }
    
}

