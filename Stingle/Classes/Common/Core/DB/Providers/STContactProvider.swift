//
//  STDataBaseContactProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/12/21.
//

import CoreData

protocol IContactProviderObserver {
    
}

extension STDataBase {
    
    class ContactProvider {
        
        typealias ManagedModel = STCDContact
        typealias Model = STContact
        typealias Observer = IContactProviderObserver
        
        let container: STDataBaseContainer
        private let observer = STObserverEvents<IContactProviderObserver>()
        
        required init(container: STDataBaseContainer) {
            self.container = container
        }
        
    }

}

extension STDataBase.ContactProvider: IDataBaseProvider {

    func addObject(_ listener: IContactProviderObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObject(_ listener: IContactProviderObserver) {
        self.observer.removeObject(listener)
    }
        
    func newBatchInsertRequest(with contacts: [STContact], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
        
        var lastDate: Date? = nil
        var jsons = [[String : Any]]()
        
        try contacts.forEach { (contact) in
            let json = try contact.toManagedModelJson()
            jsons.append(json)
            let currentLastDate = lastDate ?? contact.dateModified
            if currentLastDate <= contact.dateModified {
                lastDate = contact.dateModified
            }
        }
        
        guard let myLastDate = lastDate else {
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        let insertRequest = NSBatchInsertRequest(entityName: ManagedModel.entityName, objects: jsons)
        insertRequest.resultType = .statusOnly
        return (insertRequest, myLastDate)
    }
    
}
