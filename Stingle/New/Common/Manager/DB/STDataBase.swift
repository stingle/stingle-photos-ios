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
    let dbInfoProvider: DBInfoProvider
    
    init() {
        self.userProvider = UserProvider(container: self.container)
        self.galleryProvider = GalleryProvider(container: self.container)
        self.albumsProvider = AlbumsProvider(container: self.container)
        self.albumFilesProvider = AlbumFilesProvider(container: self.container)
        self.trashProvider = TrashProvider(container: self.container)
        self.contactProvider = ContactProvider(container: self.container)
        self.dbInfoProvider = DBInfoProvider(container: self.container)
    }
    
    func sync(_ sync: STSync, finish: @escaping (IError?) -> Void) {
        self.didStartSync()
        let context = self.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType
        context.performAndWait {
            do {
                let oldInfo = self.dbInfoProvider.dbInfo
                let info = try self.syncImportFiles(sync: sync, in: context, dbInfo: oldInfo)
                
                if context.hasChanges {
                    try context.save()
                }
                
                let deleteTime = try self.deleteFiles(deletes: sync.deletes, in: context, lastDelSeenTime: info.lastDelSeenTime)
                info.lastDelSeenTime = deleteTime
                self.dbInfoProvider.update(model: info)
                
                if context.hasChanges {
                    try context.save()
                }
                self.container.viewContext.reset()
                
            } catch {
                finish(DataBaseError.error(error: error))
                return
            }
            
        }
        
        self.endSync()
        finish(nil)
        
    }
    
    func deleteAll() {
        self.galleryProvider.deleteAll()
        self.albumsProvider.deleteAll()
        self.albumFilesProvider.deleteAll()
        self.trashProvider.deleteAll()
        self.contactProvider.deleteAll()
        self.dbInfoProvider.deleteAll()
        self.userProvider.deleteAll()
        self.container.saveContext()
    }
    
    func reloadData() {
        self.galleryProvider.reloadData()
        self.albumsProvider.reloadData()
        self.albumFilesProvider.reloadData()
        self.trashProvider.reloadData()
        self.contactProvider.reloadData()
    }
    
    func deleteFilesIfNeeded(files: [STLibrary.File]) {
        let context = self.container.newBackgroundContext()
        var fileNames = [String]()
        
        files.forEach { file in
            fileNames.append(file.file)
        }
        
        context.performAndWait {
                        
            let galleryFiles = self.galleryProvider.fetch(fileNames: fileNames, context: context)
            let albumFiles = self.albumFilesProvider.fetch(fileNames: fileNames, context: context)
            let trashFile = self.trashProvider.fetch(fileNames: fileNames, context: context)
           
            let deleteFiles = files.filter { file in
                let galleryContains = galleryFiles.contains(where: { $0.file == file.file })
                if galleryContains {
                    return false
                }
                let albumContains = albumFiles.contains(where: { $0.file == file.file })
                if albumContains {
                    return false
                }
                let trashContains = trashFile.contains(where: { $0.file == file.file })
                if trashContains {
                    return false
                }
                return true
            }
            
            STApplication.shared.fileSystem.deleteFiles(files: deleteFiles)
        }
        
    }
    
    //MARK: - private func
    
    private func endSync() {
        self.galleryProvider.finishSync()
        self.albumFilesProvider.finishSync()
        self.albumsProvider.finishSync()
        self.trashProvider.finishSync()
        self.contactProvider.finishSync()
    }
    
    private func didStartSync() {
        self.galleryProvider.didStartSync()
        self.albumFilesProvider.didStartSync()
        self.albumsProvider.didStartSync()
        self.trashProvider.didStartSync()
        self.contactProvider.didStartSync()
    }
    
    private func syncImportFiles(sync: STSync, in context: NSManagedObjectContext, dbInfo: STDBInfo) throws -> STDBInfo {
        let lastSeenTime = try self.galleryProvider.sync(db: sync.files ?? [], context: context, lastDate: dbInfo.lastSeenTime)
        let lastAlbumsSeenTime = try self.albumsProvider.sync(db: sync.albums ?? [], context: context, lastDate: dbInfo.lastAlbumsSeenTime)
        let lastTrashSeenTime = try self.trashProvider.sync(db: sync.trash ?? [], context: context, lastDate: dbInfo.lastTrashSeenTime)
        let lastAlbumFilesSeenTime = try self.albumFilesProvider.sync(db: sync.albumFiles ?? [], context: context, lastDate: dbInfo.lastAlbumFilesSeenTime)
        let lastContactsSeenTime = try self.contactProvider.sync(db: sync.contacts ?? [], context: context, lastDate: dbInfo.lastContactsSeenTime)
                
        let infon = STDBInfo(lastSeenTime: lastSeenTime,
                             lastTrashSeenTime: lastTrashSeenTime,
                             lastAlbumsSeenTime: lastAlbumsSeenTime,
                             lastAlbumFilesSeenTime: lastAlbumFilesSeenTime,
                             lastDelSeenTime: nil,
                             lastContactsSeenTime: lastContactsSeenTime,
                             spaceUsed: sync.spaceUsed,
                             spaceQuota: sync.spaceQuota)
        return infon
    }
    
    private func deleteFiles(deletes: STLibrary.DeleteFile?, in context: NSManagedObjectContext, lastDelSeenTime: Date) throws -> Date {
        let lastSeenTimeDelete = try self.galleryProvider.deleteObjects(deletes?.gallery, in: context, lastDate: lastDelSeenTime)
        let lastAlbumsSeenTimeDelete = try self.albumsProvider.deleteObjects(deletes?.albums, in: context, lastDate: lastDelSeenTime)
        let lastAlbumFilesSeenTimeDelete = try self.albumFilesProvider.deleteObjects(deletes?.albumFiles, in: context, lastDate: lastDelSeenTime)
        let lastTrashRecovorsSeenTimeDelete = try self.trashProvider.deleteObjects(deletes?.recovors, in: context, lastDate: lastDelSeenTime)
        let lastTrashhDeletesSeenTimeDelete = try self.trashProvider.deleteObjects(deletes?.trashDeletes, in: context, lastDate: lastDelSeenTime)
        let lastContactsSeenTimeDelete = try self.contactProvider.deleteObjects(deletes?.contacts, in: context, lastDate: lastDelSeenTime)
        let timeDeletes = max(lastSeenTimeDelete, lastAlbumsSeenTimeDelete, lastAlbumFilesSeenTimeDelete, lastTrashRecovorsSeenTimeDelete, lastTrashhDeletesSeenTimeDelete, lastContactsSeenTimeDelete)
        return timeDeletes
    }
        
}

extension STDataBase {
    
    func addAlbumFile(albumFile: STLibrary.AlbumFile, reloadData: Bool) {
        let context = self.container.viewContext
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        guard let album: STLibrary.Album = albumsProvider.fetch(identifiers: [albumFile.albumId], context: context).first else {
            return
        }
        let newAlbum = STLibrary.Album(albumId: album.albumId,
                                       encPrivateKey: album.encPrivateKey,
                                       publicKey: album.publicKey,
                                       metadata: album.metadata,
                                       isShared: album.isShared,
                                       isHidden: album.isHidden,
                                       isOwner: album.isOwner,
                                       isLocked: album.isLocked,
                                       isRemote: album.isRemote,
                                       permissions: album.permissions,
                                       members: album.members,
                                       cover: album.cover,
                                       dateCreated: album.dateCreated,
                                       dateModified: Date(),
                                       managedObjectID: album.managedObjectID)
        
        albumsProvider.update(models: [newAlbum], reloadData: reloadData, context: context)
        albumFilesProvider.add(models: [albumFile], reloadData: reloadData, context: context)
        
    }
    
}

extension STDataBase {
    
    enum DataBaseError: IError {
       
        case parsError
        case dateNotFound
        case error(error: Error)
        
        var message: String {
            switch self {
            case .parsError:
                return "error_unknown_error".localized
            case .dateNotFound:
                return "error_unknown_error".localized
            case .error(let error):
                if let iError = error as? IError {
                    return iError.message
                }
                return error.localizedDescription
            }
        }
    }
    
}

