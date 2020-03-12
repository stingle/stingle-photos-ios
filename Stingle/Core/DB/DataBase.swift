
import Foundation
import CoreData
class DataBase {
	
	private let container:NSPersistentContainer
	
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
	}
	
	public func add(spfile:SPFile) {
		let context = container.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.undoManager = nil
		context.performAndWait {
			let file = NSEntityDescription.insertNewObject(forEntityName: spfile.mo(), into: context) as! FileMO
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
	}
	
	public func add(files:[SPFile]) {
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
	
	func filesFilteredByDate() -> Dictionary<Date, Array<SPFile>>? {
		
		let keypathExp = NSExpression(forKeyPath: "date")
		let expression = NSExpression(forFunction: "count:", arguments: [keypathExp])
		
		let countDesc = NSExpressionDescription()
		countDesc.expression = expression
		countDesc.name = "count"
		countDesc.expressionResultType = .integer64AttributeType

		let datesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Files")
		datesFetchRequest.propertiesToFetch = ["date"]
		datesFetchRequest.propertiesToGroupBy = ["date"]
		datesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
		datesFetchRequest.resultType = .dictionaryResultType
		do {
			var result = Dictionary<Date, Array<SPFile>>()
			let datesFetchResult = try container.viewContext.fetch(datesFetchRequest)
			for item in datesFetchResult {
				let dict = item as! Dictionary<String, Date>
				guard let date = dict["date"] else {
					return nil
				}
				let filesFetchRequest = NSFetchRequest<FileMO>(entityName: "Files")
				filesFetchRequest.predicate = NSPredicate(format: "date == %@", date as NSDate)
				let filesFetchResult = try container.viewContext.fetch(filesFetchRequest)
				var files:[SPFile] = []
				for file in filesFetchResult {
					files.append(SPFile(file: file))
				}
				result[date] = files
			}
			return result
		} catch {
			print(error)
			return nil
		}
	}
	
	func getAllFiles() -> [SPFile]? {
		let filesFetchRequest = NSFetchRequest<FileMO>(entityName: "Files")
		do {
			let filesFetchResult = try container.viewContext.fetch(filesFetchRequest)
			var files:[SPFile] = []
			for item in filesFetchResult {
				files.append(SPFile(file: item))
			}
			return files
		} catch {
			print(error)
			return nil
		}
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
