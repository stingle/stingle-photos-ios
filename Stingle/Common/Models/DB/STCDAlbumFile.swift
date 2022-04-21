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
    
    func diffStatus(with model: Model) -> STDataBase.ModelDiffStatus {
        guard self.identifier == model.identifier else {
            return .none
        }
        guard let dateModified = self.dateModified else { return .low }
        let lhsVersion = Int(self.version ?? "") ?? .zero
        let rhsVersion = Int(model.version) ?? .zero
        if lhsVersion == rhsVersion ? dateModified < model.dateModified : lhsVersion < rhsVersion {
            return .low
        } else if lhsVersion == rhsVersion && dateModified == model.dateModified {
            return .equal
        }
        return .high
    }
    
}
