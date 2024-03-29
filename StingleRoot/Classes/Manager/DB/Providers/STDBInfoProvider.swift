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
            let context = self.container.viewContext
            context.performAndWait {
                guard let cdInfo = self.getInfo(context: context) else {
                    info.createCDModel(context: context)
                    self.container.saveContext(context)
                    return
                }
                
                info.update(model: cdInfo)
                self.container.saveContext(context)
                context.reset()
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
