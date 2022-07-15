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
        
        if !self.shouldMigrate() {
            let environment = STEnvironment.current
            let id = "group." + environment.appFileSharingBundleId
            let storeURL = URL.storeURL(for: id, databaseName: self.modelName)
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.undoManager = nil
        persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in

            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else  {
                do {
                    try self.migraIfNeeded(persistentContainer: persistentContainer)
                } catch {
                    fatalError("Unresolved error \(error)")
                }
            }
        })
   
        return persistentContainer
    }
    
    
}

public extension URL {

    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        return self.containerURL(for: appGroup).appendingPathComponent("\(databaseName).sqlite")
    }
    
    static func containerURL(for appGroup: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }
        return fileContainer
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


extension STDataBaseContainer {
    
    static let currentDBVersion:Int = 1
    
    func migratedVersion() -> Int {
        return UserDefaults.standard.integer(forKey: "data.base.container.migrated.version.\(self.modelName)")
    }
    
    func shouldMigrate() -> Bool {
        return Self.currentDBVersion != self.migratedVersion() && !STEnvironment.current.appRunIsExtension
    }
    
    func updateMigrateVersion(version: Int) {
        UserDefaults.standard.set(version, forKey: "data.base.container.migrated.version.\(self.modelName)")
        UserDefaults.standard.synchronize()
    }
    
    func migraIfNeeded(persistentContainer: NSPersistentContainer) throws {
        
        guard self.shouldMigrate() else {
            return
        }
        
        let currentDBVersion = Self.currentDBVersion
        for index in self.migratedVersion()..<currentDBVersion {
            try self.migrate(to: index, persistentContainer: persistentContainer)
        }
        
    }
    
    func migrate(to version: Int, persistentContainer: NSPersistentContainer) throws {
        switch version {
        case 0:
            try self.migrateV0_1(persistentContainer: persistentContainer)
        default:
            break
        }
    }
    
    func migrateV0_1(persistentContainer: NSPersistentContainer) throws {
        guard let oldStore =  persistentContainer.persistentStoreCoordinator.persistentStores.first else {
            return
        }
        let environment = STEnvironment.current
        let id = "group." + environment.appFileSharingBundleId
        let storeURL = URL.storeURL(for: id, databaseName: self.modelName)
        
        try persistentContainer.persistentStoreCoordinator.migratePersistentStore(oldStore, to: storeURL, options: nil, withType: NSSQLiteStoreType)
        self.updateMigrateVersion(version: 1)
        
    }
    
}
