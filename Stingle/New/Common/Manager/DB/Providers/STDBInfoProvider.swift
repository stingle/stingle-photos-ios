//
//  STDBInfoProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/13/21.
//

import CoreData

extension STDataBase {
    
    class DBInfoProvider: DataBaseProvider<STDBInfo> {
        
        private var myDBInfo: STDBInfo?
        
        override func deleteAll(completion: ((IError?) -> Void)? = nil) {
            super.deleteAll { [weak self] error in
                if error == nil {
                    self?.myDBInfo = nil
                }
                completion?(error)
            }
        }
               
        func update(model info: STDBInfo) {
            self.myDBInfo = info
            let context = self.container.viewContext
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.undoManager = nil
            context.performAndWait {
                guard let cdInfo = self.getInfo(context: context) else {
                    STCDDBInfo(model: info, context: context)
                    self.container.saveContext(context)
                    return
                }
                cdInfo.update(model: info, context: context)
                self.container.saveContext(context)
                context.reset()
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

extension STDataBase.DBInfoProvider {
    
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
