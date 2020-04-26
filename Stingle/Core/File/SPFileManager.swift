import Foundation

enum SPFolder  : String {
	///Paths where downloaded images or videos should be placed
	case StorageThumbs = "thumbs"
	case StorageOriginals = "originals"
		
	///Private files folder
	case Private = "private"
}

public enum FileExistence: Equatable {
	case none
	case file
	case directory
}

public func ==(lhs: FileExistence, rhs: FileExistence) -> Bool {
	
	switch (lhs, rhs) {
	case (.none, .none),
		 (.file, .file),
		 (.directory, .directory):
		return true
		
	default: return false
	}
}

extension FileManager {
	public func existence(atUrl url: URL) -> FileExistence {
		
		var isDirectory: ObjCBool = false
		let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectory)
		
		switch (exists, isDirectory.boolValue) {
		case (false, _): return .none
		case (true, false): return .file
		case (true, true): return .directory
		}
	}
	
	public func subDirectories (atPath:String) -> [String]? {
		guard let subpaths = self.subpaths(atPath: atPath) else {
			return nil
		}
		var subDirs:[String] = [String]()
		for item in subpaths {
			var isDirectory: ObjCBool = false
			self.fileExists(atPath: "\(atPath)/\(item)", isDirectory: &isDirectory)
			if isDirectory.boolValue {
				subDirs.append("\(atPath)/\(item)")
			}
		}
		return subDirs
	}
}

class SPFileManager : FileManager {
	
	private static var storagePath:URL? {
		get {
			guard let path = self.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
				return nil
			}
			guard let  home = SPApplication.user?.homeFolder else {
				return nil
			}
			let homePath = "\(path)\(home)"
			guard let homePathUrl = URL(string: homePath) else {
				return nil
			}
			if self.default.existence(atUrl: homePathUrl) != .directory {
				do {
					try self.default.createDirectory(at: homePathUrl, withIntermediateDirectories: false, attributes: nil)
				} catch {
					return nil
				}
			}
			return homePathUrl
		}
	}
	
	private static var privatePath:URL? {
		get {
			guard let path = self.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
				return nil
			}
			let privatePath = "\(path)\(SPFolder.Private.rawValue)"
			guard let privatePathUrl = URL(string: privatePath) else {
				return nil
			}
			if self.default.existence(atUrl: privatePathUrl) != .directory {
				do {
					try self.default.createDirectory(at: privatePathUrl, withIntermediateDirectories: false, attributes: nil)
				} catch {
					return nil
				}
			}
			return privatePathUrl
		}
	}

	
	public static func homeFolder() -> URL? {
		return self.storagePath
	}
	
	public static func folder(for folder:SPFolder) -> URL? {
		if folder == .Private {
			return privatePath
		}
		guard let dest = SPFileManager.fullPathOfFile(fileName: folder.rawValue, isDirectory: true) else {
			return nil
		}
		if self.default.existence(atUrl: dest) != .directory {
			do {
				try self.default.createDirectory(at: dest, withIntermediateDirectories: true, attributes: nil)
			} catch {
				return nil
			}
		}
		return dest
	}
	
	public static func moveToFolder(fileURL:URL?, with name:String?, folder:SPFolder) throws -> Bool {
		//TODO : Throw exception
		guard let fileURL = fileURL, let name = name else {
			return false
		}
		let destFolder:URL? = self.folder(for: folder)
		guard var dest = destFolder else {
			return false
		}
		dest.appendPathComponent(name)
		do {
			try self.default.moveItem(at: fileURL, to: dest)
		} catch {
			throw error
		}
		return true
	}
	
	private static func fullPathOfFile(fileName:String, isDirectory:Bool = false) -> URL? {
		guard let fullPath = (SPFileManager.storagePath?.appendingPathComponent(fileName, isDirectory: isDirectory)) else {
			return nil
		}
		return fullPath
	}
}
