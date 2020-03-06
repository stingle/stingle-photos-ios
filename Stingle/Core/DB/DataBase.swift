
import Foundation
import CoreData
class DataBase {
	
	public let container:NSPersistentContainer
	
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
			guard let file = NSEntityDescription.insertNewObject(forEntityName: "Files", into: context) as? FileMO else {
				return
			}
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
	
	func getAllFiles() -> [SPFile]? {
		let fetchRequest = NSFetchRequest<FileMO>(entityName: "Files")
		do {
			let files = try container.viewContext.fetch(fetchRequest)
			var result:[SPFile] = []
			for item in files {
				result.append(SPFile(file: item))
			}
			return result
		} catch {
			print(error)
		}
		return []
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
