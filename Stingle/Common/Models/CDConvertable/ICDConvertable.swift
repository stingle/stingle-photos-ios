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
    @discardableResult
    func createCDModel(context: NSManagedObjectContext) -> ManagedModel
    func update(model: ManagedModel)
}

extension ICDConvertable {
    
    @discardableResult
    func createCDModel(context: NSManagedObjectContext) -> ManagedModel {
        let cdModel = ManagedModel(context: context)
        self.update(model: cdModel)
        return cdModel
    }
    
    func toManagedModelJson() throws -> [String: Any] {
        guard let json = self.toJson() else {
            throw STLibrary.LibraryError.parsError
        }
        return json
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
    func diffStatus(with rhs: ManagedModel) -> STDataBase.ModelModifyStatus
    static func > (lhs: Self, rhs: Self) -> Bool
    
    func updateLowMode(model: ManagedModel)
}

//MARK: - ManagedObject

protocol IManagedObject: NSManagedObject {
    var identifier: String? { get }
}

extension IManagedObject {
        
    static var entityName: String {
        return String(describing: self.self)
    }
    
}

protocol ISynchManagedObject: IManagedObject {
    var dateCreated: Date? { get }
    var dateModified: Date? { get }
}
