//
//  STDataBase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData


class STDataBase {
    
    enum SyncProviderType {
        case gallery
        case trash
        case albums
        case albumFiles
        case contact
    }
    
    struct SyncInfo<T: ICDSynchConvertable> {
        let inserts: Set<T>
        let updates: Set<T>
        let deletes: Set<T>
    }
    
    struct DBSyncInfo {
        let gallery: SyncInfo<GalleryProvider.Model>
        let trash: SyncInfo<TrashProvider.Model>
        let albums: SyncInfo<AlbumsProvider.Model>
        let albumFiles: SyncInfo<AlbumFilesProvider.Model>
        let contact: SyncInfo<ContactProvider.Model>
        let trashRecovers: Set<TrashProvider.Model>
        let dbInfo: STDBInfo
    }
    
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
    
    func sync(_ sync: STSync, finish: @escaping () -> Void, willFinish: @escaping (DBSyncInfo) -> Void, failure: @escaping (IError) -> Void) {
        self.didStartSync()
        let context = self.container.backgroundContext
        context.performAndWait { [weak self] in
            guard let weakSelf = self else { return }
            do {
                let oldInfo = weakSelf.dbInfoProvider.dbInfo
                let synchInfo = try weakSelf.syncImportFiles(sync: sync, in: context, dbInfo: oldInfo)
                weakSelf.dbInfoProvider.update(model: synchInfo.dbInfo, context: context, notify: false)
                
                if context.hasChanges {
                    try context.save()
                }
                weakSelf.container.viewContext.reset()
                willFinish(synchInfo)
                
                DispatchQueue.main.async {
                    weakSelf.endSync()
                    finish()
                }
                
            } catch {
                failure(DataBaseError.error(error: error))
                return
            }
        }
        
        
                
        
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
    
    func filtrNotExistFiles(files: [STLibrary.File]) -> [STLibrary.File] {
        
        let context = self.container.backgroundContext
        var fileNames = [String]()
        
        files.forEach { file in
            fileNames.append(file.file)
        }
        
        return context.performAndWait {
                        
            let galleryFiles = self.galleryProvider.fetch(fileNames: fileNames, context: context)
            let albumFiles = self.albumFilesProvider.fetch(fileNames: fileNames, context: context)
            let trashFile = self.trashProvider.fetch(fileNames: fileNames, context: context)
           
            let resultFiles = files.filter { file in
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
            
            return resultFiles
        }
        
    }
    
    func filtrNotExistFileNames(fileNames: [String]) -> [String] {
       
        let context = self.container.backgroundContext
        return context.performAndWait {
            
            let galleryFiles = self.galleryProvider.fetch(fileNames: fileNames, context: context)
            let albumFiles = self.albumFilesProvider.fetch(fileNames: fileNames, context: context)
            let trashFile = self.trashProvider.fetch(fileNames: fileNames, context: context)
           
            let resultFiles = fileNames.filter { fileName in
                let galleryContains = galleryFiles.contains(where: { $0.file == fileName })
                if galleryContains {
                    return false
                }
                let albumContains = albumFiles.contains(where: { $0.file == fileName })
                if albumContains {
                    return false
                }
                let trashContains = trashFile.contains(where: { $0.file == fileName })
                if trashContains {
                    return false
                }
                return true
            }
            
            return resultFiles
        }
        
    }
    
    //MARK: - private func
    
    private func endSync() {
        self.galleryProvider.finishSync()
        self.albumFilesProvider.finishSync()
        self.albumsProvider.finishSync()
        self.trashProvider.finishSync()
        self.contactProvider.finishSync()
        self.dbInfoProvider.notifyAllUpdates()
    }
    
    private func didStartSync() {
        self.galleryProvider.didStartSync()
        self.albumFilesProvider.didStartSync()
        self.albumsProvider.didStartSync()
        self.trashProvider.didStartSync()
        self.contactProvider.didStartSync()
    }
    
    private func syncImportFiles(sync: STSync, in context: NSManagedObjectContext, dbInfo: STDBInfo) throws -> DBSyncInfo {
       
        let gallerySync = try self.galleryProvider.sync(db: sync.files ?? [], context: context, lastDate: dbInfo.lastSeenTime)
        let albumsSync = try self.albumsProvider.sync(db: sync.albums ?? [], context: context, lastDate: dbInfo.lastAlbumsSeenTime)
        let trashSync = try self.trashProvider.sync(db: sync.trash ?? [], context: context, lastDate: dbInfo.lastTrashSeenTime)
        let albumFilesSync = try self.albumFilesProvider.sync(db: sync.albumFiles ?? [], context: context, lastDate: dbInfo.lastAlbumFilesSeenTime)
        let contactSync = try self.contactProvider.sync(db: sync.contacts ?? [], context: context, lastDate: dbInfo.lastContactsSeenTime)
        
        let deletes = try self.deleteFiles(deletes: sync.deletes, in: context, lastDelSeenTime: dbInfo.lastDelSeenTime)

        let infon = STDBInfo(lastSeenTime: gallerySync.lastDate,
                             lastTrashSeenTime: trashSync.lastDate,
                             lastAlbumsSeenTime: albumsSync.lastDate,
                             lastAlbumFilesSeenTime: albumFilesSync.lastDate,
                             lastDelSeenTime: deletes.lastSeen,
                             lastContactsSeenTime: contactSync.lastDate,
                             spaceUsed: sync.spaceUsed,
                             spaceQuota: sync.spaceQuota)
        
        
        let galleryInfo = SyncInfo<GalleryProvider.Model>(inserts: gallerySync.insert, updates: gallerySync.updated, deletes: deletes.gallery)
        let trashInfo = SyncInfo<TrashProvider.Model>(inserts: trashSync.insert, updates: trashSync.updated, deletes: deletes.trashDeletes)
        let albumsInfo = SyncInfo<AlbumsProvider.Model>(inserts: albumsSync.insert, updates: albumsSync.updated, deletes: deletes.albums)
        let albumFilesInfo = SyncInfo<AlbumFilesProvider.Model>(inserts: albumFilesSync.insert, updates: albumFilesSync.updated, deletes: deletes.albumFiles)
        let contact = SyncInfo<ContactProvider.Model>(inserts: contactSync.insert, updates: contactSync.updated, deletes: deletes.contact)
        
        let result = DBSyncInfo(gallery: galleryInfo,
                                trash: trashInfo,
                                albums: albumsInfo,
                                albumFiles: albumFilesInfo,
                                contact: contact,
                                trashRecovers: deletes.trashRecovers,
                                dbInfo: infon)
        
        return result
    }
    
    private func deleteFiles(deletes: STLibrary.DeleteFile?, in context: NSManagedObjectContext, lastDelSeenTime: Date) throws -> (lastSeen: Date, gallery: Set<GalleryProvider.Model>, trashDeletes: Set<TrashProvider.Model>, albums: Set<AlbumsProvider.Model>, albumFiles: Set<AlbumFilesProvider.Model>, contact: Set<ContactProvider.Model>, trashRecovers: Set<TrashProvider.Model>) {
        
        let gallery = try self.galleryProvider.deleteObjects(deletes?.gallery, in: context, lastDate: lastDelSeenTime)
        let albums = try self.albumsProvider.deleteObjects(deletes?.albums, in: context, lastDate: lastDelSeenTime)
        let albumFiles = try self.albumFilesProvider.deleteObjects(deletes?.albumFiles, in: context, lastDate: lastDelSeenTime)
        let trashRecovers = try self.trashProvider.deleteObjects(deletes?.recovers, in: context, lastDate: lastDelSeenTime)
        let trashDeletes = try self.trashProvider.deleteObjects(deletes?.trashDeletes, in: context, lastDate: lastDelSeenTime)
        let contact = try self.contactProvider.deleteObjects(deletes?.contacts, in: context, lastDate: lastDelSeenTime)
        
        let timeDeletes = max(gallery.lastDate, albums.lastDate, albumFiles.lastDate, trashRecovers.lastDate, trashDeletes.lastDate, contact.lastDate)
        return (timeDeletes, gallery.deleteds, trashDeletes.deleteds, albums.deleteds, albumFiles.deleteds, contact.deleteds, trashRecovers.deleteds)
    }
        
}

extension STDataBase {
    
    func addAlbumFile(albumFile: STLibrary.AlbumFile, reloadData: Bool) {
        let context = self.container.backgroundContext
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
        
        albumFilesProvider.add(models: [albumFile], reloadData: reloadData, context: context)
        albumsProvider.update(models: [newAlbum], reloadData: reloadData, context: context)
    }
    
    func addAlbumFiles(albumFiles: [STLibrary.AlbumFile], album: STLibrary.Album, reloadData: Bool) {
        let context = self.container.backgroundContext
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
       
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
        
        albumFilesProvider.add(models: albumFiles, reloadData: reloadData, context: context)
        albumsProvider.update(models: [newAlbum], reloadData: reloadData, context: context)
        
    }
    
}

extension STDataBase {
    
    enum DataBaseChangeType {
        case add
        case update
        case delete
    }
    
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

