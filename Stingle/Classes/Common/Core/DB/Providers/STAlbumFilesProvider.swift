//
//  STAlbumFilesProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import CoreData

protocol IAlbumFilesProviderObserver {
    
}

extension STDataBase {
    
    class AlbumFilesProvider {
        
        typealias ManagedModel = STCDAlbumFile
        typealias Model = STLibrary.AlbumFile
        typealias Observer = IAlbumFilesProviderObserver
        
        let container: STDataBaseContainer
        private let observer = STObserverEvents<IAlbumFilesProviderObserver>()
        
        required init(container: STDataBaseContainer) {
            self.container = container
        }
        
    }

}

extension STDataBase.AlbumFilesProvider: IDataBaseProvider {

    func addObject(_ listener: IAlbumFilesProviderObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObject(_ listener: IAlbumFilesProviderObserver) {
        self.observer.removeObject(listener)
    }
    
    func newBatchInsertRequest(with albumFiles: [STLibrary.AlbumFile], context: NSManagedObjectContext) throws -> (request: NSBatchInsertRequest, lastDate: Date) {
        var lastDate: Date? = nil
        var jsons = [[String : Any]]()
        
        try albumFiles.forEach { (albumFile) in
            let json = try albumFile.toManagedModelJson()
            jsons.append(json)
            let currentLastDate = lastDate ?? albumFile.dateModified
            if currentLastDate <= albumFile.dateModified {
                lastDate = albumFile.dateModified
            }
        }
        
        guard let myLastDate = lastDate else {
            throw STDataBase.DataBaseError.dateNotFound
        }
        
        let insertRequest = NSBatchInsertRequest(entity: ManagedModel.entity(), objects: jsons)
        insertRequest.resultType = .statusOnly        return (insertRequest, myLastDate)
    }
    
}
