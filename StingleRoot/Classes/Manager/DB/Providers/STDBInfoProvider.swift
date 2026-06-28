//
//  STDBInfoProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/13/21.
//

import CoreData

extension STDataBase {
    
    public class DBInfoProvider: DataBaseProvider<STDBInfo> {
        
        private var myDBInfo: STDBInfo?
        
        public override func deleteAll(completion: ((IError?) -> Void)? = nil) {
            super.deleteAll { [weak self] error in
                if error == nil {
                    self?.myDBInfo = nil
                }
                completion?(error)
            }
        }
               
        public func update(model info: STDBInfo) {
            self.myDBInfo = info
            // Persist on the BACKGROUND context, never the main `viewContext`. This is called once
            // per uploaded file (from the uploader's queue, for the `spaceUsed` the server returns on
            // each upload). The old code did a synchronous `performAndWait` on the main `viewContext`
            // *and then* `context.reset()` — and `reset()` tears down every managed object the gallery
            // FRC and visible cells hold, forcing a full refault on the next access. In the completion
            // burst at the end of a large upload that ran dozens of times back-to-back on the main
            // thread and froze the UI (the "freeze when upload finishes"). The in-memory `myDBInfo` is
            // updated synchronously above so readers (and the observers below) see the new value
            // immediately; the background save auto-merges the single row into the viewContext.
            // Snapshot `info` on the calling thread before dispatching: `info` is the shared
            // `myDBInfo` instance and the uploader mutates it (via `update(with:)`) on the next
            // completion. The old synchronous `performAndWait` blocked the caller during the read,
            // so it couldn't race; an async write must read its own private copy instead.
            let snapshot = STDBInfo(lastGallerySeenTime: info.lastGallerySeenTime,
                                    lastTrashSeenTime: info.lastTrashSeenTime,
                                    lastAlbumsSeenTime: info.lastAlbumsSeenTime,
                                    lastAlbumFilesSeenTime: info.lastAlbumFilesSeenTime,
                                    lastDelSeenTime: info.lastDelSeenTime,
                                    lastContactsSeenTime: info.lastContactsSeenTime,
                                    spaceUsed: info.spaceUsed,
                                    spaceQuota: info.spaceQuota,
                                    managedObjectID: info.managedObjectID)
            let context = self.container.backgroundContext
            context.perform { [weak self] in
                guard let self = self else { return }
                if let cdInfo = self.getInfo(context: context) {
                    snapshot.update(model: cdInfo)
                } else {
                    snapshot.createCDModel(context: context)
                }
                if context.hasChanges {
                    #if DEBUG
                    let __ts = CFAbsoluteTimeGetCurrent()
                    #endif
                    try? context.save()
                    #if DEBUG
                    let __dt = CFAbsoluteTimeGetCurrent() - __ts
                    if __dt > 0.1 { NSLog("[STPERF] DBInfoProvider CONTEXT.SAVE took %.3fs", __dt) }
                    #endif
                }
            }
            self.observerProvider.forEach { obs in
                DispatchQueue.main.async {
                    obs.dataBaseProvider(didUpdated: self, models: [info])
                }
            }
        }
        
        public func update(model info: STDBInfo, context: NSManagedObjectContext, notify: Bool) {
            self.myDBInfo = info
            if  let cdInfo = self.getInfo(context: context) {
                info.update(model: cdInfo)
            }
        }
        
        public func notifyAllUpdates() {
            let info = self.dbInfo
            self.observerProvider.forEach { obs in
                DispatchQueue.main.async {
                    obs.dataBaseProvider(didUpdated: self, models: [info])
                }
            }
        }
        
        //MARK: - Private func
        
        private func getInfo(context: NSManagedObjectContext) -> STCDDBInfo? {
            let fetchRequest = NSFetchRequest<STCDDBInfo>(entityName: STCDDBInfo.entityName)
            do {
                guard let info = try context.fetch(fetchRequest).first else {
                    return nil
                }
                return info
            } catch {
                return nil
            }
        }
        
    }
    
}

public extension STDataBase.DBInfoProvider {
    
    var dbInfo: STDBInfo {
        
        if let myDBInfo = self.myDBInfo {
            return myDBInfo
        }
        
        guard let info = self.getInfo(context: self.container.viewContext) else {
            self.myDBInfo = STDBInfo()
            return self.myDBInfo!
        }
        do {
            self.myDBInfo = try STDBInfo(model: info)
            return self.myDBInfo!
        } catch  {
            self.myDBInfo = STDBInfo()
            return self.myDBInfo!
        }
    }
    
}
