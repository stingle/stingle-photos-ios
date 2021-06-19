//
//  ICDConvertable.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData

//MARK: - Model

protocol IDataBaseProviderModel: AnyObject {
    var identifier: String { get }
}

protocol ICDConvertable: IDataBaseProviderModel, Encodable {
    associatedtype ManagedModel: IManagedObject
    init(model: ManagedModel) throws
    var managedObjectID: NSManagedObjectID? { get }
    func toManagedModelJson() throws -> [String: Any]
}

extension ICDConvertable {
    
    func toManagedModelJson() throws -> [String: Any] {
        guard let json = self.toJson() else {
            throw STLibrary.LibraryError.parsError
        }
        return json
    }
    
    func createManagedModel(context: NSManagedObjectContext) -> ManagedModel {
        return ManagedModel(model: self as! Self.ManagedModel.Model, context: context)
    }
    
}


//MARK: - ManagedObject

protocol IManagedObject: NSManagedObject {
    associatedtype Model: ICDConvertable
    init(model: Model, context: NSManagedObjectContext)
    func update(model: Model, context: NSManagedObjectContext?)
    
    func createModel() throws -> Model
    
    var identifier: String? { get }
}

extension IManagedObject {
    
    @discardableResult
    init(model: Model, context: NSManagedObjectContext) {
        self.init(context: context)
        self.update(model: model, context: context)
    }
    
    init(model: Model) {
        self.init()
        self.update(model: model, context: nil)
    }
    
    static var entityName: String {
        return String(describing: self.self)
    }
    
}
