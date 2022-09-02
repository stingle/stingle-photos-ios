//
//  STDataBase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData

public class STDataBase {
    
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
        let upgrade: Set<T>
        let deletes: Set<T>
        
        init(inserts: Set<T>, updates: Set<T>, upgrade: Set<T>, deletes: Set<T>) {
            self.inserts = inserts
            self.updates = updates
            self.upgrade = upgrade
            self.deletes = deletes
        }
        
        init(syncInfo: SyncInfo<T>, inserts: Set<T>? = nil, updates: Set<T>? = nil, upgrade: Set<T>? = nil, deletes: Set<T>? = nil) {
            let inserts = inserts ?? syncInfo.inserts
            let updates = updates ?? syncInfo.updates
            let deletes = deletes ?? syncInfo.deletes
            let upgrade = upgrade ?? syncInfo.upgrade
            self.init(inserts: inserts, updates: updates, upgrade: upgrade, deletes: deletes)
        }
        
        static var empty: SyncInfo<T> {
            return SyncInfo(inserts: [], updates: [], upgrade: [], deletes: [])
        }
       
    }
    
    public enum ModelModifyStatus {
        
        public enum ModifyType {
            case update
            case upgrade
        }
    
        case none
        case equal
        case high(type: ModifyType)
        case low
    }
    
    struct DBSyncInfo {
        let gallery: SyncInfo<STLibrary.GaleryFile>
        let trash: SyncInfo<STLibrary.TrashFile>
        let albums: SyncInfo<STLibrary.Album>
        let albumFiles: SyncInfo<STLibrary.AlbumFile>
        let contact: SyncInfo<STContact>
        let dbInfo: STDBInfo
    }
        
    public let userProvider: UserProvider
    public let dbInfoProvider: DBInfoProvider
    public let galleryProvider: SyncProvider<STLibrary.GaleryFile, STLibrary.DeleteFile.Gallery>
    public let albumsProvider: SyncProvider<STLibrary.Album, STLibrary.DeleteFile.Album>
    public let albumFilesProvider: SyncProvider<STLibrary.AlbumFile, STLibrary.DeleteFile.AlbumFile>
    public let trashProvider: SyncProvider<STLibrary.TrashFile, STLibrary.DeleteFile.Trash>
    public let contactProvider: SyncProvider<STContact, STLibrary.DeleteFile.Contact>
    
    private let container: STDataBaseContainer
        
    init() {
        let modelBundles = [Bundle(for: STCDUser.self), Bundle(for: STDBInfo.self), Bundle(for: STCDGaleryFile.self), Bundle(for: STCDAlbumFile.self), Bundle(for: STCDAlbum.self), Bundle(for: STCDTrashFile.self), Bundle(for: STCDContact.self)]
        
        self.container = STDataBaseContainer(modelName: "StingleModel", modelBundles: modelBundles)
        self.userProvider = UserProvider(container: self.container)
        self.dbInfoProvider = DBInfoProvider(container: self.container)
        
        self.galleryProvider = .init(container: self.container, providerType: .gallery)
        self.albumsProvider = .init(container: self.container, providerType: .albums)
        self.albumFilesProvider = .init(container: self.container, providerType: .albumFiles)
        self.trashProvider = .init(container: self.container, providerType: .trash)
        self.contactProvider = .init(container: self.container, providerType: .contact)
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
                
                DispatchQueue.global().async {
                    willFinish(synchInfo)
                    DispatchQueue.main.async {
                        context.performAndWait {
                            do {
                                try context.save()
                                weakSelf.endSync()
                                finish()
                            } catch {
                                failure(DataBaseError.error(error: error))
                                STLogger.log(error: error)
                            }
                        }
                    }
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
    
    func filtrNotExistFiles(files: [ILibraryFile]) -> [ILibraryFile] {
        
        let context = self.container.backgroundContext
        var identifiers = [String]()
        
        files.forEach { file in
            identifiers.append(file.identifier)
        }
        
        return context.performAndWait {
                                    
            let galleryFiles = self.galleryProvider.fetchObjects(identifiers: identifiers)
            let albumFiles = self.albumFilesProvider.fetchObjects(identifiers: identifiers, context: context)
            let trashFile = self.trashProvider.fetchObjects(identifiers: identifiers, context: context)
           
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
            
            let galleryFiles = self.galleryProvider.fetchObjects(fileNames: fileNames, context: context)
            let albumFiles = self.albumFilesProvider.fetchObjects(fileNames: fileNames, context: context)
            let trashFile = self.trashProvider.fetchObjects(fileNames: fileNames, context: context)
           
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
        
        var allTrashDeletes: [STLibrary.DeleteFile.Trash] = sync.deletes?.trashRecovers ?? []
        allTrashDeletes.append(contentsOf: sync.deletes?.trashDeletes ?? [])

        let gallerySync = try self.galleryProvider.sync(models: sync.galery, lastSyncDate: dbInfo.lastGallerySeenTime, deleteFile: sync.deletes?.gallery, lastdDeleteDate: dbInfo.lastDelSeenTime, context: context)
        let albumFilesSync = try self.albumFilesProvider.sync(models: sync.albumFiles, lastSyncDate: dbInfo.lastAlbumFilesSeenTime, deleteFile: sync.deletes?.albumFiles, lastdDeleteDate: dbInfo.lastDelSeenTime, context: context)
        let trashSync = try self.trashProvider.sync(models: sync.trash, lastSyncDate: dbInfo.lastTrashSeenTime, deleteFile: allTrashDeletes, lastdDeleteDate: dbInfo.lastDelSeenTime, context: context)
        let albumsSync = try self.albumsProvider.sync(models: sync.albums, lastSyncDate: dbInfo.lastAlbumsSeenTime, deleteFile: sync.deletes?.albums, lastdDeleteDate: dbInfo.lastDelSeenTime, context: context)
        let contactSync = try self.contactProvider.sync(models: sync.contacts, lastSyncDate: dbInfo.lastContactsSeenTime, deleteFile: sync.deletes?.contacts, lastdDeleteDate: dbInfo.lastDelSeenTime, context: context)
        
        let lastDelSeenTime = max(gallerySync.lastDeletedsDate, albumFilesSync.lastDeletedsDate, trashSync.lastDeletedsDate, albumsSync.lastDeletedsDate, contactSync.lastDeletedsDate)
        
        
        let infon = STDBInfo(lastGallerySeenTime: gallerySync.lastSynchDate,
                             lastTrashSeenTime: trashSync.lastSynchDate,
                             lastAlbumsSeenTime: albumsSync.lastSynchDate,
                             lastAlbumFilesSeenTime: albumFilesSync.lastSynchDate,
                             lastDelSeenTime: lastDelSeenTime,
                             lastContactsSeenTime: contactSync.lastSynchDate,
                             spaceUsed: sync.spaceUsed,
                             spaceQuota: sync.spaceQuota)
        
        let result = DBSyncInfo(gallery: gallerySync.syncInfo,
                                trash: trashSync.syncInfo,
                                albums: albumsSync.syncInfo,
                                albumFiles: albumFilesSync.syncInfo,
                                contact: contactSync.syncInfo,
                                dbInfo: infon)
        
        return result

    }
   
}

extension STDataBase {
    
    func addAlbumFile(albumFile: STLibrary.AlbumFile, reloadData: Bool) {
        let context = self.container.backgroundContext
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        guard let album: STLibrary.Album = albumsProvider.fetchObjects(identifiers: [albumFile.albumId], context: context).first else {
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

public extension STDataBase {
    
    enum DataBaseChangeType {
        case add
        case update
        case delete
    }
    
    enum DataBaseError: IError {
       
        case parsError
        case dateNotFound
        case error(error: Error)
        
        public var message: String {
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

