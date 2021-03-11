//
//  STDataBase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData


class STDataBase {
    
    private let container = STDataBaseContainer(modelName: "StingleModel")
    
    let userProvider: UserProvider
    let galleryProvider: GalleryProvider
    let albumsProvider: AlbumsProvider
    let albumFilesProvider: AlbumFilesProvider
    let trashProvider: TrashProvider
    let contactProvider: ContactProvider
    
    init() {
        self.userProvider = UserProvider(container: self.container)
        self.galleryProvider = GalleryProvider(container: self.container)
        self.albumsProvider = AlbumsProvider(container: self.container)
        self.albumFilesProvider = AlbumFilesProvider(container: self.container)
        self.trashProvider = TrashProvider(container: self.container)
        self.contactProvider = ContactProvider(container: self.container)
    }
    
    func sync(_ sync: STSync) {
        let context = self.container.newBackgroundContext()
        context.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        context.performAndWait {
            do {
                
                
                let _ = try self.galleryProvider.sync(db: sync.files ?? [], context: context)
                let _ = try self.albumsProvider.sync(db: sync.albums ?? [], context: context)
                let _ = try self.albumFilesProvider.sync(db: sync.albumFiles ?? [], context: context)
                let _ = try self.trashProvider.sync(db: sync.trash ?? [], context: context)
                let _ = try self.contactProvider.sync(db: sync.contacts ?? [], context: context)
                
                let lll = self.galleryProvider.getAllObjects()
                
                print("")
                
            } catch {
                print(error)
            }
        }
                
        
    }

}

extension STDataBase {
    
    enum DataBaseError: IError {
       
        case parsError
        case dateNotFound
        
        var message: String {
            switch self {
            case .parsError:
                return "nework_error_unknown_error".localized
            case .dateNotFound:
                return "nework_error_unknown_error".localized
            }
        }
    }
    
}

