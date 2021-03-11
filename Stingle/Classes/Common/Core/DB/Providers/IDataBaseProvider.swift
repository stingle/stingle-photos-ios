//
//  IDataBaseProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/10/21.
//

import CoreData

protocol ICDConvertable: Encodable {
    associatedtype ManagedModel: NSManagedObject
    init(model: ManagedModel) throws
    
    func toManagedModelJson() throws -> [String: Any]
}

extension ICDConvertable {
    
    func toManagedModelJson() throws -> [String: Any] {
        guard let json = self.toJson() else {
            throw STLibrary.LibraryError.parsError
        }
        return json
    }
    
}

protocol IManagedObject: NSManagedObject {
    associatedtype Model: ICDConvertable
    init(model: Model, context: NSManagedObjectContext)
    func update(model: Model, context: NSManagedObjectContext)
}

extension IManagedObject {
    
    @discardableResult
    init(model: Model, context: NSManagedObjectContext) {
        self.init(context: context)
        self.update(model: model, context: context)
    }
    
    static var entityName: String {
        return String(describing: self.self)
    }
    
}

protocol IDataBaseProvider {
    
    associatedtype ManagedModel: IManagedObject
    associatedtype Model: ICDConvertable
    associatedtype Observer
    
    init(container: STDataBaseContainer)
    
    var container: STDataBaseContainer { get }
    
    func addObject(_ listener: Observer)
    func removeObject(_ listener: Observer)
    
    func newBatchInsertRequest(with models: [Model], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date)
}

extension IDataBaseProvider {
    
    func getAllObjects() -> [ManagedModel] {
        let context = self.container.viewContext
        let fetchRequest = NSFetchRequest<Self.ManagedModel>(entityName: ManagedModel.entityName)
        fetchRequest.includesSubentities = false
        do {
            let result = try context.fetch(fetchRequest)
            return result
        } catch {
            return []
        }
    }
    
    func deleteAll() {
        let taskContext = self.container.newBackgroundContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedModel.entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeStatusOnly
            _ = try? taskContext.execute(batchDeleteRequest)
        }
    }
    
    //MARK: - Sync
    
    func sync(db models: [Model], context: NSManagedObjectContext) throws -> Date {
        let insert = try self.newBatchInsertRequest(with: models, context: context)
        _ = try context.execute(insert.request)
        return insert.lastDate
    }
    
    func newBatchInsertRequest(with files: [Model], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
        throw STDataBase.DataBaseError.dateNotFound
    }

    
}
