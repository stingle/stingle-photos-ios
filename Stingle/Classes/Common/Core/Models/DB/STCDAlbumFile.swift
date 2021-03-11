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
public class STCDAlbumFile: STCDFile {

    func update(model: STLibrary.AlbumFile, context: NSManagedObjectContext) {
        super.update(model: model, context: context)
        self.albumId = model.albumId
    }
    
}
