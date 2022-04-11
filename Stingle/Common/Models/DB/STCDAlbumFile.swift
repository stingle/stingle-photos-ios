//
//  STCDAlbumFile+CoreDataClass.swift
//  
//
//  Created by Khoren Asatryan on 3/8/21.
//
//

import Foundation
import CoreData

@objc(STCDAlbumFile)
public class STCDAlbumFile: NSManagedObject {

}

extension STCDAlbumFile: IManagedSynchObject {
    
    func update(model: STLibrary.AlbumFile) {
        self.file = model.file
        self.version = model.version
        self.headers = model.headers
        self.dateCreated = model.dateCreated
        self.dateModified = model.dateModified
        self.albumId = model.albumId
        self.isRemote = model.isRemote
        self.identifier = model.identifier
    }
    
    func createModel() throws -> STLibrary.AlbumFile {
        return try STLibrary.AlbumFile(model: self)
    }
    
    func mastUpdate(with model: STLibrary.AlbumFile) -> Bool {
        guard self.identifier == model.identifier else {
            return false
        }
        
        guard let dateModified = self.dateModified else { return true }
        let lhsVersion = Int(self.version ?? "") ?? .zero
        let rhsVersion = Int(model.version) ?? .zero
        
        return lhsVersion == rhsVersion ? dateModified < model.dateModified : lhsVersion < rhsVersion
    }
    
}
