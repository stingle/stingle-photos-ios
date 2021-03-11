//
//  STDataBase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData

class STDataBaseContainer {
    
    private let modelName: String
    
    private lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    // MARK: - Core Data Saving support

    func saveContext() {
        let context = self.container.viewContext
        self.saveContext(context)
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return self.container.newBackgroundContext()
    }
    
    func performAndWait<T>(context: NSManagedObjectContext, _ executeBlock: @escaping () -> T) -> T {
        var result: T!
        context.performAndWait( {
            result = executeBlock()
        })
        return result
    }
        
}
