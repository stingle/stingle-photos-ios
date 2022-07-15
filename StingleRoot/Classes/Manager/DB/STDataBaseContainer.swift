//
//  STDataBase.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import CoreData

public class STDataBaseContainer {
    
    private let modelName: String
    private let modelBundles: [Bundle]
    
    private lazy var container: NSPersistentContainer = {
        return self.getContaner()
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
    
    init(modelName: String, modelBundles: [Bundle]) {
        self.modelName = modelName
        self.modelBundles = modelBundles
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
    
    private func getContaner() -> NSPersistentContainer {
        if STEnvironment.current.appRunIsExtension {
            return self.getSharedContaner()
        } else {
            return self.getSharedContaner()
        }
    }
    
    private func getSharedContaner() -> NSPersistentContainer {
        
        guard let model = NSManagedObjectModel.mergedModel(from: self.modelBundles) else {
            fatalError("model not found")
        }

        let persistentContainer = NSPersistentContainer(name: self.modelName, managedObjectModel: model)

        let environment = STEnvironment.current
        let id = "group." + environment.appFileSharingBundleId
        
        let storeURL = URL.storeURL(for: id, databaseName: environment.productName)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        persistentContainer.persistentStoreDescriptions = [storeDescription]
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.undoManager = nil
        persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
        
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
   
        return persistentContainer
    }
    
    private func getDefaultContaner() -> NSPersistentContainer {
        return self.createContaner()
    }
    
    private func createContaner<T: NSPersistentContainer>() -> T {
                
        guard let model = NSManagedObjectModel.mergedModel(from: self.modelBundles) else {
            fatalError("model not found")
        }
        let container = T(name: self.modelName, managedObjectModel: model)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        
        return container
    }
    
}

public extension URL {

    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

class SharedPersistentContainer: NSPersistentContainer {
//
//    override open class func defaultDirectoryURL() -> URL {
//        let environment = STEnvironment.current
//        let id = "group." + environment.appFileSharingBundleId
//        var storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
//        storeURL = storeURL?.appendingPathComponent(environment.productName)
//        return storeURL!
//    }
//
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
