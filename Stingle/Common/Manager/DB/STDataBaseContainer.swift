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
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let background = self.newBackgroundContext()
        background.automaticallyMergesChangesFromParent = true
        background.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return background
    }()
    
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
            context.performAndWait {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return self.container.newBackgroundContext()
    }
    
}

extension NSManagedObjectContext {
    
    func performAndWait<T>(_ executeBlock: @escaping () -> T) -> T {
        var result: T!
        self.performAndWait( {
            result = executeBlock()
        })
        return result
    }
    
    func performAndWait<T>(_ executeBlock: @escaping () -> T?) -> T? {
        var result: T?
        self.performAndWait( {
            result = executeBlock()
        })
        return result
    }
    
}
