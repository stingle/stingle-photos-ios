//
//  STDBInfoProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/13/21.
//

import CoreData

extension STDataBase {
    
    class DBInfoProvider: DataBaseProvider<STDBInfo> {
               
        func update(model info: STDBInfo) {
            let context = self.container.newBackgroundContext()
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
        guard  let info = self.getInfo(context: self.container.viewContext) else {
            return STDBInfo()
        }
        do {
            return try STDBInfo(model: info)
        } catch  {
            return STDBInfo()
        }
    }
    
}
