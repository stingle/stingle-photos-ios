//
//  ICDConvertable.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import CoreData

//MARK: - Model

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


//MARK: - ManagedObject

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
