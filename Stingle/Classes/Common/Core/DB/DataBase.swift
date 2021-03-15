import Foundation
import CoreData

class DataBase : NSObject {
	
	private let container:NSPersistentContainer
	
	static private var db:DataBase?
	
	static func shared() throws -> DataBase {
		if db == nil {
			db = DataBase()
			_ = try db?.load()
		}
		return db!
	}
	
	private lazy var galleryFRC:NSFetchedResultsController<FileMO> = {
		let filesFetchRequest = NSFetchRequest<FileMO>(entityName: "Files")
		filesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
		return NSFetchedResultsController(fetchRequest: filesFetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: "date", cacheName: "Files")
	}()
	
	private lazy var trashFRC:NSFetchedResultsController<FileMO> = {
		let trashFetchRequest = NSFetchRequest<FileMO>(entityName: "Trash")
		trashFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
		return NSFetchedResultsController(fetchRequest: trashFetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: "date", cacheName: "Trash")
	}()
	
	private override init() {
		container = NSPersistentContainer(name: "StingleModel_old")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		container.viewContext.automaticallyMergesChangesFromParent = true
		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		container.viewContext.undoManager = nil
		container.viewContext.shouldDeleteInaccessibleFaults = true
	}
	
	public func load() throws -> Bool {
		try galleryFRC.performFetch()
		galleryFRC.delegate = self
		try trashFRC.performFetch()
		trashFRC.delegate = self
		return true
	}
	
	private func frc<T:SPFileInfo>(for type:T.Type) -> NSFetchedResultsController<FileMO>? {
		if type is SPFile.Type {
			return galleryFRC
		} else if type is SPTrashFile.Type {
			return trashFRC
		}
		return nil
	}
	
	public func add<T:SPFileInfo>(files:[T]) {
		for file in files {
			add(spfile: file)
		}
	}
	
	private func add<T:SPFileInfo>(spfile:T) {
		let context = container.viewContext
		context.performAndWait {
			let file = NSEntityDescription.insertNewObject(forEntityName: T.mo(), into: context) as! FileMO
			file.update(file: spfile)
			if context.hasChanges {
				do {
					try context.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return
				}
				context.reset()
			}
		}
	}
	
	public func delete<F:SPFileInfo>(file:String, from:String) -> F? {
		let context = container.viewContext
		let fetchRequest = NSFetchRequest<FileMO>(entityName: from)
		fetchRequest.predicate = NSPredicate(format: "name == %@", file)
		do {
			let objects = try context.fetch(fetchRequest)
			guard let obj = objects.first else {
				return nil
			}
			let result = F(file: obj)
			context.performAndWait {
				context.delete(obj)
				if context.hasChanges {
					do {
						try context.save()
					} catch {
						print("Error: \(error)\nCould not save Core Data context.")
						return
					}
					context.reset()
				}
			}
			return result
		} catch {
			print(error)
			return nil
		}
	}

	public func deleteAll(from:String) {
		let context = container.viewContext
		let fetchRequest = NSFetchRequest<FileMO>(entityName: from)
		do {
			let objects = try context.fetch(fetchRequest)
			for obj in objects {
				context.performAndWait {
					context.delete(obj)
				}
			}
			context.performAndWait {
				if context.hasChanges {
					do {
						try context.save()
					} catch {
						print("Error: \(error)\nCould not save Core Data context.")
						return
					}
					context.reset()
				}
			}
		} catch {
			print(error)
		}
	}

	public func delete<T:SPFileInfo, F:SPFileInfo>(file:T) -> F? {
		let context = container.viewContext
		let fetchRequest = NSFetchRequest<FileMO>(entityName: T.mo())
		fetchRequest.predicate = NSPredicate(format: "name == %@", file.name)
		do {
			let objects = try context.fetch(fetchRequest)
			guard let obj = objects.first else {
				return nil
			}
			let result = F(file: obj)
			context.performAndWait {
				context.delete(obj)
				if context.hasChanges {
					do {
						try context.save()
					} catch {
						print("Error: \(error)\nCould not save Core Data context.")
						return
					}
					context.reset()
				}
			}
			return result
		} catch {
			print(error)
			return nil
		}
	}
		
	public func update(parts:SPUpdateInfo.Parts) {
		add(files: parts.files)
		add(files: parts.trash)
	}
		
	public func isFileExist<T:SPFileInfo>(name:String) -> T? {
		let fetchRequest = NSFetchRequest<FileMO>(entityName: T.mo())
		fetchRequest.predicate = NSPredicate(format: "name == %@", name)
		do {
			 let objects = try container.viewContext.fetch(fetchRequest)
			guard let obj = objects.first else {
				return nil
			}
			return T(file: obj)
		} catch {
			print(error)
			return nil
		}
	}
	
	public func updateFile<T:SPFileInfo>(file:T) -> Bool {
		let fetchRequest = NSFetchRequest<FileMO>(entityName: T.mo())
		fetchRequest.predicate = NSPredicate(format: "name == %@", file.name)
		do {
			 let objects = try container.viewContext.fetch(fetchRequest)
			guard let obj = objects.first else {
				return false
			}
			obj.update(file: file)
			if container.viewContext.hasChanges {
				do {
					try container.viewContext.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return false
				}
				container.viewContext.reset()
			}
			return true
		} catch {
			print(error)
			return false
		}
	}
	
	public func markFileAsRemote(name:String) -> Bool {
		return false
	}
	
	public func markFileAsReuploaded(name:String) -> Bool {
		return false
	}
	
	private func getAppinfoMO (context:NSManagedObjectContext) -> AppInfoMO? {
		var info:AppInfoMO? = nil
		let fetchRequest = NSFetchRequest<AppInfoMO>(entityName: "AppInfo")
		do {
			info = try context.fetch(fetchRequest).first
			if info == nil {
				guard let newInfo = NSEntityDescription.insertNewObject(forEntityName: "AppInfo", into: context) as? AppInfoMO else {
					return nil
				}
				newInfo.update(lastSeen: 0, lastDelSeen: 0 , spaceQuota: "1024", spaceUsed: "0", userId: -1)
				info = newInfo
			}
		} catch {
			return nil
		}
		return info
	}
	
	func getAppInfo() -> AppInfo? {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		var info:AppInfo? = nil
		context.performAndWait {
			guard let infoMO = getAppinfoMO(context: context) else {
				return
			}
			info = AppInfo(info: infoMO)
			if context.hasChanges {
				do {
					try context.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return
				}
				context.reset()
			}
		}
		return info
	}
		
	func updateAppInfo(info: AppInfo) {
		guard let userId = info.userId else {
			return
		}
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		context.performAndWait {
			let infoMo = getAppinfoMO(context: context)
			if infoMo != nil {
				infoMo?.update(lastSeen: info.lastSeen, lastDelSeen: info.lastDelSeen, spaceQuota: info.spaceQuota, spaceUsed: info.spaceUsed, userId: userId)
			}
			if context.hasChanges {
				do {
					try context.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return
				}
				context.reset()
			}
		}
	}
	
	func updateUserId(userId:Int) {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		context.performAndWait {
			guard let infoMO = getAppinfoMO(context: context) else {
				return
			}
			infoMO.userId = userId
			if context.hasChanges {
				do {
					try context.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return
				}
				context.reset()
			}
		}
	}
		
	func getUserId() -> Int? {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		guard let infoMO = getAppinfoMO(context: context) else {
			return nil
		}
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				print("Error: \(error)\nCould not save Core Data context.")
				return nil
			}
		}
		return infoMO.userId
	}

	func getUser(userId: Int) -> User? {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		let fetchRequest = NSFetchRequest<UserMO>(entityName: "User")
		fetchRequest.predicate = NSPredicate(format: "userId ==%d", userId)
		do {
			guard let user = try context.fetch(fetchRequest).first else {
				return nil
			}
			return User(mo: user)
		} catch {
			return nil
		}
	}
	
	func updateUser(user: User) {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		let fetchRequest = NSFetchRequest<UserMO>(entityName: "User")
		fetchRequest.predicate = NSPredicate(format: "userId ==%d", user.userId)
		context.performAndWait {
			do {
				if let userMO = try context.fetch(fetchRequest).first {
					userMO.update(user: user)
				} else {
					guard let newUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as? UserMO else {
						return
					}
					newUser.update(user:user)
				}
			} catch {
				print(error)
			}

			if context.hasChanges {
				do {
					try context.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return
				}
				context.reset()
			}
		}
	}

	
	func numberOfSections<T:SPFileInfo>(for fileType:T.Type) -> Int {
		guard let frc = frc(for:fileType) else {
			return 0
		}
		if let sections = frc.sections  {
			return sections.count
		} else {
			guard let sections = frc.sections else {
				return 0
			}
			return sections.count
		}
	}
	
	public func numberOfRows<T:SPFileInfo>(for section:Int, with fileType:T.Type) -> Int {
		guard let frc = frc(for:fileType) else {
			return 0
		}
		guard let sections = frc.sections else {
			return 0
		}
		return sections[section].numberOfObjects
	}
	
	public func sectionTitle<T:SPFileInfo>(for section:Int, with fileType:T.Type) -> String? {
		guard let frc = frc(for:fileType) else {
			return nil
		}
		guard let sections = frc.sections else {
			return nil
		}
		let sectionInfo = sections[section]
		return sectionInfo.name
	}

	func fileForIndexPath<T:SPFileInfo>(indexPath:IndexPath, with type:T.Type) -> T? {
		guard let frc = frc(for: type) else {
			return nil
		}
		let objMO = frc.object(at: indexPath)
		return T.init(file: objMO)
	}
	
	func fileForIndexPath(indexPath:IndexPath) -> SPFile? {
		let objMO = galleryFRC.object(at: indexPath)
		return SPFile.init(file: objMO)
	}
	
	func trashFileForIndexPath(indexPath:IndexPath) -> SPTrashFile? {
		let objMO = trashFRC.object(at: indexPath)
		return SPTrashFile.init(file: objMO)
	}

	
	func indexPath<T:SPFileInfo>(for file:String, with type:T.Type) -> IndexPath? {
		let fetchRequest = NSFetchRequest<FileMO>(entityName: type.mo())
		fetchRequest.predicate = NSPredicate(format: "name == %@", file)
		do {
			 let objects = try container.viewContext.fetch(fetchRequest)
			guard let obj = objects.first else {
				return nil
			}
			guard let frc = frc(for: type) else {
				return nil
			}
			return frc.indexPath(forObject: obj)
		} catch {
			print(error)
			return nil
		}
	}
	
	func filesSortedByDate<T:SPFileInfo> () -> [T]? {
		guard let frc = frc(for: T.self) else {
			return nil
		}
		var files:[T] = []
		guard let objects = frc.fetchedObjects else {
			return nil
		}
		for item in  objects {
			files.append(T(file: item))
		}
		return files
	}
	
	func filesCount<T:SPFileInfo>(for type:T.Type) -> Int {
		guard let frc = frc(for: type) else {
			return 0
		}
		guard let objects = frc.fetchedObjects else {
			return 0
		}
		return objects.count
	}
	
	func fileForIndex<T:SPFileInfo>(index:Int, for type:T.Type) -> T? {
		guard let frc = frc(for: type) else {
			return nil
		}
		guard let objs = frc.fetchedObjects else {
			return nil
		}
		let obj = objs[index]
		return T.init(file: obj)
	}
	
	func index<T:SPFileInfo>(of file:SPFileInfo, with type:T.Type) -> Int {
		guard let frc = frc(for: type) else {
			return 0
		}
		guard let objs = frc.fetchedObjects else {
			return 0
		}
		let index = objs.firstIndex { (fileMO) -> Bool in
			return fileMO.name == file.name
		}
		if index != nil {
			return index!
		}
		return 0
	}
	
	func index<T:SPFileInfo>(for indexPath:IndexPath, of type:T.Type) ->Int {
		guard let file = fileForIndexPath(indexPath: indexPath, with: type) else {
			return NSNotFound
		}
		return index(of: file, with: type)
	}
	
	func objectsForRange<T:SPFileInfo>(start:Int, count:Int) -> [T]? {
		return nil
	}
	
	//MARK: - Update file Info
	
	func marFileAsRemote(file:SPFile) {
		guard let frc = frc(for: SPFile.self) else {
			return
		}
		let objs:[FileMO]? = frc.fetchedObjects?.filter {$0.name == file.name}
		objs?.first?.isRemote = true
		let context = container.viewContext
		context.performAndWait {
			if context.hasChanges {
				do {
					try context.save()
				} catch {
					print("Error: \(error)\nCould not save Core Data context.")
					return
				}
				context.reset()
			}
		}

	}
	
	
	public func deleteAll() {
		
	}
	
	func commit() {
		let context = container.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
}


//MARK: - NSFetched Resluts Cotroller Delegate

extension DataBase: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if controller == galleryFRC {
			EventManager.dispatch(event: SPEvent(type: SPEvent.UI.updates.begin.rawValue, info:nil))
		} else if controller == trashFRC {
			EventManager.dispatch(event: SPEvent(type: SPEvent.UI.updates.begin.rawValue, info:nil))
		}
    }

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch(type) {
		case .insert:
			if controller == galleryFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.insert.gallery.rawValue, info:[SPEvent.Keys.IndexPaths.rawValue : [newIndexPath]]))
			} else if controller == trashFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.insert.trash.rawValue, info:[SPEvent.Keys.IndexPaths.rawValue : [newIndexPath]]))
			}
			break
		case .delete:
			print("delete : ", indexPath ?? "")
			if controller == galleryFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.delete.gallery.rawValue, info:[SPEvent.Keys.IndexPaths.rawValue : [newIndexPath]]))
			} else if controller == trashFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.delete.trash.rawValue, info:[SPEvent.Keys.IndexPaths.rawValue : [newIndexPath]]))
			}
			break
		default:
			break
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		switch(type) {
		case .insert:
			if controller == galleryFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.insert.gallery.rawValue, info:[SPEvent.Keys.Sections.rawValue : IndexSet(integer: sectionIndex)]))
			} else if controller == trashFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.insert.trash.rawValue, info:[SPEvent.Keys.Sections.rawValue : IndexSet(integer: sectionIndex)]))
			}
			break
		case .delete:
			if controller == galleryFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.delete.gallery.rawValue, info:[SPEvent.Keys.Sections.rawValue : IndexSet(integer: sectionIndex)]))
			} else if controller == trashFRC {
				EventManager.dispatch(event: SPEvent(type: SPEvent.DB.delete.trash.rawValue, info:[SPEvent.Keys.Sections.rawValue : IndexSet(integer: sectionIndex)]))
			}
			break
		default:
			break
		}

	}
	
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if controller == galleryFRC {
			EventManager.dispatch(event: SPEvent(type: SPEvent.UI.updates.end.rawValue, info:nil))
		} else if controller == trashFRC {
			EventManager.dispatch(event: SPEvent(type: SPEvent.UI.updates.end.rawValue, info:nil))
		}
    }

}
