import Foundation
import CoreData
class DataBase {
	
	private let container:NSPersistentContainer
	
	fileprivate let galleryFRC:NSFetchedResultsController<FileMO>
	fileprivate let trashFRC:NSFetchedResultsController<FileMO>
	
	
	init() {
		container = NSPersistentContainer(name: "StingleModel")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		container.viewContext.automaticallyMergesChangesFromParent = true
		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		container.viewContext.undoManager = nil
		container.viewContext.shouldDeleteInaccessibleFaults = true
		
		let filesFetchRequest = NSFetchRequest<FileMO>(entityName: "Files")
		filesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
		galleryFRC = NSFetchedResultsController(fetchRequest: filesFetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: "date", cacheName: "Files")
		
		let trashFetchRequest = NSFetchRequest<FileMO>(entityName: "Trash")
		trashFetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
		trashFRC = NSFetchedResultsController(fetchRequest: trashFetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: "Trash")
		
	}
	
	private func frc<T:SPFileInfo>(for:T.Type) -> NSFetchedResultsController<FileMO>? {
		if T.self is SPFile.Type {
			return galleryFRC
		} else if T.self is SPTrashFile.Type {
			return trashFRC
		}
		return nil
	}
	
	public func add<T:SPFileInfo>(spfile:T) {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
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
	
	public func add(deletes:[SPDeletedFile]) {
		for item in deletes {
			add(deleted: item)
		}
	}
	
	public func add(deleted:SPDeletedFile) {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		context.performAndWait {
			let file = NSEntityDescription.insertNewObject(forEntityName: deleted.mo(), into: context) as! DeletedFileMO
			file.update(info: deleted)
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
	
	public func update(parts:SPUpdateInfo.Parts) {
		add(files: parts.files)
		add(files: parts.trash)
		add(deletes: parts.deletes)
		do {
			try galleryFRC.performFetch()
			try trashFRC.performFetch()
		} catch {
			print(error)
		}
	}
	
	public func add<T:SPFileInfo>(files:[T]) {
		for file in files {
			add(spfile: file)
		}
	}
	
	public func isFileExist(name:String) -> Bool {
		return false
	}
	
	public func updateFile(file:SPFile) -> Bool {
		return false
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
				newInfo.update(lastSeen: 0, lastDelSeen: 0)
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
	
	func updateAppInfo(info:AppInfo) {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		context.performAndWait {
			let infoMo = getAppinfoMO(context: context)
			if infoMo != nil {
				infoMo?.update(lastSeen: info.lastSeen, lastDelSeen: info.lastDelSeen)
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
			do {
				try frc.performFetch()
			} catch {
				print(error)
				return 0
			}
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
	
	func fileForIndexPath<T:SPFileInfo>(indexPath:IndexPath) -> T? {
		guard let frc = frc(for: T.self) else {
			return nil
		}
		let objMO = frc.object(at: indexPath)
		return T.init(file: objMO)
	}
	
	func indexPath<T:SPFileInfo>(for file:String, with type:T.Type) -> IndexPath? {
		let fetchRequest = NSFetchRequest<FileMO>(entityName: T.mo())
		fetchRequest.predicate = NSPredicate(format: "file == %@", file)
		do {
			guard let obj = try container.viewContext.fetch(fetchRequest).first else {
				return nil
			}
			guard let frc = frc(for: T.self) else {
				return nil
			}
			return frc.indexPath(forObject: obj)
		} catch {
			print(error)
			return nil
		}
	}
	
	func objectsForRange<T:SPFileInfo>(start:Int, count:Int) -> [T]? {
		return nil
	}
	
	func getAllFilesCount() -> Int {
		return 0
	}
	
	func getFiles(mode:Int, sort:Int) -> [SPFile]? {
		return nil
	}
	
	
	func getReuploadFilesList() -> [SPFile]? {
		return nil
	}
	
	public func deleteFile(fileName:String) {
		
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


//MARK: - Helpers

extension DataBase {
	
	/*func indexPathToIndex<T:SPFileInfo>(indexPath:IndexPath, type:T.Type) -> Int {
	guard let ip = indexPaths(type: type) else {
	return 0
	}
	var index = 0
	for i in 0...indexPath.section  - 1 {
	index += ip[i]!
	}
	index += indexPath.row
	return index
	}
	
	func indexToIndexPath<T:SPFileInfo> (index:Int, type:T.Type) -> IndexPath? {
	guard let ip = indexPaths(type: type) else {
	return nil
	}
	var idx = 0
	var section = 0
	var row = 0
	while idx < index {
	if idx + ip[section]! >= index {
	row = index - idx
	break
	}
	idx += ip[section]!
	section += 1
	}
	return IndexPath(row: row, section: section)
	}*/
}
