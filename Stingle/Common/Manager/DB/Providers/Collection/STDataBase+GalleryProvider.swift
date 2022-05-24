//
//  STGalleryProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData
import UIKit

extension STDataBase {
    
    class GalleryProvider: SyncProvider<STLibrary.GaleryFile, STLibrary.DeleteFile.Gallery> {
        
        override var providerType: SyncProviderType {
            return .gallery
        }
        
    }
    
}
