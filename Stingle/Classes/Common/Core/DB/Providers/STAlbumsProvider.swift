//
//  STAlbumsProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

protocol IAlbumsProviderObserver {
    
}

extension STDataBase {
    
    class AlbumsProvider {
        
        typealias ManagedModel = STCDAlbum
        typealias Model = STLibrary.Album
        typealias Observer = IAlbumsProviderObserver
        
        let container: STDataBaseContainer
        private let observer = STObserverEvents<IAlbumsProviderObserver>()
        
        required init(container: STDataBaseContainer) {
            self.container = container
        }
        
    }

}

extension STDataBase.AlbumsProvider: IDataBaseProvider {

    func addObject(_ listener: IAlbumsProviderObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObject(_ listener: IAlbumsProviderObserver) {
        self.observer.removeObject(listener)
    }
    
    func newBatchInsertRequest(with albums: [STLibrary.Album], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
        var lastDate: Date? = nil
        var jsons = [[String : Any]]()
        
        try albums.forEach { (album) in
            let json = try album.toManagedModelJson()
            jsons.append(json)
            let currentLastDate = lastDate ?? album.dateModified
            if currentLastDate <= album.dateModified {
                lastDate = album.dateModified
            }
        }
        
        guard let myLastDate = lastDate else {
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        let insertRequest = NSBatchInsertRequest(entity: ManagedModel.entity(), objects: jsons)
        insertRequest.resultType = .statusOnly
        return (insertRequest, myLastDate)
    }
    
}
