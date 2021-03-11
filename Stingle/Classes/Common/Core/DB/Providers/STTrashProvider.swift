//
//  STTrashProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

protocol ITrashProviderObserver {
    
}

extension STDataBase {
    
    class TrashProvider {
        
        typealias ManagedModel = STCDTrashFile
        typealias Model = STLibrary.TrashFile
        typealias Observer = ITrashProviderObserver
        
        let container: STDataBaseContainer
        private let observer = STObserverEvents<ITrashProviderObserver>()
        
        required init(container: STDataBaseContainer) {
            self.container = container
        }
        
    }

}

extension STDataBase.TrashProvider: IDataBaseProvider {

    func addObject(_ listener: ITrashProviderObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObject(_ listener: ITrashProviderObserver) {
        self.observer.removeObject(listener)
    }
        
    func newBatchInsertRequest(with trashFiles: [STLibrary.TrashFile], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
        
        var lastDate: Date? = nil
        var jsons = [[String : Any]]()
        
        try trashFiles.forEach { (file) in
            let json = try file.toManagedModelJson()
            jsons.append(json)
            let currentLastDate = lastDate ?? file.dateModified
            if currentLastDate <= file.dateModified {
                lastDate = file.dateModified
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
