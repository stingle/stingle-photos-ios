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
        
    var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let background = self.newBackgroundContext()
        background.automaticallyMergesChangesFromParent = true
        background.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return background
    }()
    
    private lazy var container: NSPersistentContainer = {
        return self.getContaner()
    }()
    
    private lazy var storeURL: URL = {
        let environment = STEnvironment.current
        let id = "group." + environment.appFileSharingBundleId
        let path = "Databases" + "/\(self.modelName)"
        var storeURL = URL.storeURL(for: id, databaseName: self.modelName, pathExtation: path)
        let fileManager = FileManager.default
        var dbUrl = storeURL
        dbUrl.deleteLastPathComponent()
        if !fileManager.fileExists(atPath: dbUrl.path) {
            try? fileManager.createDirectory(at: dbUrl, withIntermediateDirectories: true)
        }
        return storeURL
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
        if STEnvironment.current.appIsExtension {
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
        if let storeDescriptions = self.getCurrentVersionStoreDescriptions() {
            persistentContainer.persistentStoreDescriptions = storeDescriptions
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
    
    static var containerSharedURL: URL {
        let appGroup = "group." + STEnvironment.current.appFileSharingBundleId
        return self.containerURL(for: appGroup)
    }

    static func storeURL(for appGroup: String, databaseName: String, pathExtation: String? = nil) -> URL {
        var containerURL = self.containerURL(for: appGroup)
        if let pathExtation = pathExtation {
            containerURL = containerURL.appendingPathComponent(pathExtation)
        }
        containerURL = containerURL.appendingPathComponent("\(databaseName).sqlite")
        return containerURL
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

fileprivate extension STDataBaseContainer {
    
    static let currentDBVersion:Int = 1
    
    func migratedVersion() -> Int {
        if STEnvironment.current.appIsExtension {
            return Self.currentDBVersion
        }
        return UserDefaults.standard.integer(forKey: "data.base.container.migrated.version.\(self.modelName)")
    }
    
    func shouldMigrate() -> Bool {
        return Self.currentDBVersion != self.migratedVersion() && !STEnvironment.current.appIsExtension
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
        let storeURL = self.storeURL
        try persistentContainer.persistentStoreCoordinator.migratePersistentStore(oldStore, to: storeURL, options: nil, withType: NSSQLiteStoreType)
        self.updateMigrateVersion(version: 1)
    }
    
    func getCurrentVersionStoreDescriptions() -> [NSPersistentStoreDescription]? {
        switch self.migratedVersion() {
        case 0:
            //The first version db using NSPersistentContainer.defaultDirectoryURL()
            return nil
        case 1:
            //For version 1 db using group app url
            let storeURL = self.storeURL
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            return [storeDescription]
        default:
            return nil
        }
    }
    
}
