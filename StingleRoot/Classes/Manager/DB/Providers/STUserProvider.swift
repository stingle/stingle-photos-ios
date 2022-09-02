//
//  STUserProvider.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData

extension STDataBase {
    
    public class UserProvider: DataBaseProvider<STUser> {
        
        public fileprivate(set) var myUser: STUser? = nil
                       
        func update(model user: STUser) {
            let context = self.container.viewContext
            context.performAndWait {
                guard let cdUser = self.getUser(context: context) else {
                    user.createCDModel(context: context)
                    self.container.saveContext(context)
                    return
                }
                user.update(model: cdUser)
                self.container.saveContext(context)
                context.reset()
                self.myUser = nil
            }
        }
        
        public override func deleteAll(completion: ((IError?) -> Void)? = nil) {
            super.deleteAll { [weak self] error in
                if error == nil {
                    self?.myUser = nil
                }
                completion?(error)
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
            return context.performAndWait { () -> STCDUser in
                let cdUser = user.createCDModel(context: context)
                self.container.saveContext(context)
                return cdUser
            }
        }
        
        private func updateMyUser() {
            guard let cdUser = self.getUser(context: self.container.viewContext) else {
                self.myUser = nil
                return
            }
            do {
                self.myUser = try STUser(model: cdUser)
            } catch  {
                self.myUser = nil
            }
        }
        
    }
    
}


public extension STDataBase.UserProvider {
    
    var user: STUser? {
        if self.myUser == nil {
            self.updateMyUser()
        }
        return self.myUser
    }
    
}
