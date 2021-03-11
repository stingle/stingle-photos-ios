//
//  STCDTrashFile.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/11/21.
//

import Foundation
import CoreData

@objc(STCDTrashFile)
public class STCDTrashFile: STCDFile {

    func update(model: STLibrary.TrashFile, context: NSManagedObjectContext) {
        super.update(model: model, context: context)
    }
        
}
