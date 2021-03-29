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
        context.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        context.performAndWait {
            do {
                let oldInfo = self.dbInfoProvider.dbInfo
                let info = try self.syncImportFiles(sync: sync, in: context, dbInfo: oldInfo)
                let deleteTime = try self.deleteFiles(deletes: sync.deletes, in: context, lastDelSeenTime: info.lastDelSeenTime)
                info.lastDelSeenTime = deleteTime
                self.dbInfoProvider.update(model: info)
                finish(nil)
            } catch {
                finish(DataBaseError.error(error: error))
            }
        }
        self.endSync()
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
        let lastAlbumFilesSeenTime = try self.albumFilesProvider.sync(db: sync.albumFiles ?? [], context: context, lastDate: dbInfo.lastAlbumFilesSeenTime)
        let lastTrashSeenTime = try self.trashProvider.sync(db: sync.trash ?? [], context: context, lastDate: dbInfo.lastTrashSeenTime)
        let lastContactsSeenTime = try self.contactProvider.sync(db: sync.contacts ?? [], context: context, lastDate: dbInfo.lastContactsSeenTime)
                
        let infon = STDBInfo(lastSeenTime: lastSeenTime,
                             lastTrashSeenTime: lastTrashSeenTime,
                             lastAlbumsSeenTime: lastAlbumsSeenTime,
                             lastAlbumFilesSeenTime: lastAlbumFilesSeenTime,
                             lastDelSeenTime: nil,
                             lastContactsSeenTime: lastContactsSeenTime)
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

