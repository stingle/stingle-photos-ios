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

protocol ICDConvertable: IDataBaseProviderModel, Encodable, Hashable {
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
    
    func hash(into hasher: inout Hasher) {
        return self.identifier.hash(into: &hasher)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}

protocol ICDSynchConvertable: ICDConvertable {
    
    var dateModified: Date { get }
    static func > (lhs: Self, rhs: Self) -> Bool
    
}


//MARK: - ManagedObject

protocol IManagedObject: NSManagedObject {
    associatedtype Model: ICDConvertable
    
    var identifier: String? { get }
    
    init(model: Model, context: NSManagedObjectContext)
    func update(model: Model)
    
    func createModel() throws -> Model
    
}

extension IManagedObject {
    
    @discardableResult
    init(model: Model, context: NSManagedObjectContext) {
        self.init(context: context)
        self.update(model: model)
    }
    
    init(model: Model) {
        self.init()
        self.update(model: model)
    }
    
    static var entityName: String {
        return String(describing: self.self)
    }
    
}

protocol IManagedSynchObject: IManagedObject   where Model: ICDSynchConvertable {
    
    var dateModified: Date? { get }
    func mastUpdate(with model: Model) -> Bool
    
}
