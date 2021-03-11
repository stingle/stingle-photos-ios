//
//  STUserProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData

extension STDataBase {
    
    class UserProvider: DataBaseProvider<STUser, STCDUser> {
               
        func update(model user: STUser) {
            let context = self.container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.undoManager = nil
            context.performAndWait {
                guard let cdUser = self.getUser(context: context) else {
                    STCDUser(model: user, context: context)
                    self.container.saveContext(context)
                    return
                }
                cdUser.update(model: user, context: context)
                self.container.saveContext(context)
                context.reset()
            }
        }
        
        //MARK: - Private func
        
        private func getUser(context: NSManagedObjectContext) -> STCDUser? {
            let fetchRequest = NSFetchRequest<STCDUser>(entityName: STCDUser.entityName)
            do {
                guard let user = try context.fetch(fetchRequest).first else {
                    return nil
                }
                return user
            } catch {
                return nil
            }
        }
                
        private func createUserAndSave(context: NSManagedObjectContext, for user: STUser) -> STCDUser {
            return self.container.performAndWait(context: context) { () -> STCDUser in
                let cdUser = STCDUser(model: user, context: context)
                self.container.saveContext(context)
                return cdUser
            }
        }
        
    }
    
}

extension STDataBase.UserProvider {
    
    var user: STUser? {
        guard  let cdUser = self.getUser(context: self.container.viewContext) else {
            return nil
        }
        do {
            return try STUser(model: cdUser)
        } catch  {
            return nil
        }
    }
    
}
