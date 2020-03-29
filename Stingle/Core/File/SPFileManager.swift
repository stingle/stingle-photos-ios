import Foundation

public enum Folder: String {
	case main = "main"
	case thumb = "thumb"
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
}



class SPFileManager : FileManager {
	
	private static var storagePath:URL? {
		get {
			guard let path = self.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
				return nil
			}
			guard let home = SPApplication.user?.homeFolder else {
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
	
	public static func moveToFolder(fileURL:URL?, with name:String?, folder:Folder) throws -> Bool {
		//TODO : Throw exception
		guard let fileURL = fileURL, let name = name else {
			return false
		}
		var destFolder:URL? = nil
		switch folder {
		case .thumb:
			destFolder = SPFileManager.thumbFolder()
			break
		case .main:
			destFolder = SPFileManager.mainFolder()
			break
		}
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
	
	public static func fullPathOfFile(fileName:String, isDirectory:Bool = false) -> URL? {
		guard let fullPath = (SPFileManager.storagePath?.appendingPathComponent(fileName, isDirectory: isDirectory)) else {
			return nil
		}
		return fullPath
	}
	
	public static func thumbFolder() -> URL? {
		guard let dest = SPFileManager.fullPathOfFile(fileName: Folder.thumb.rawValue, isDirectory: true) else {
			return nil
		}
		if self.default.existence(atUrl: dest) != .directory {
			do {
				try self.default.createDirectory(at: dest, withIntermediateDirectories: false, attributes: nil)
			} catch {
				return nil
			}
		}
		return dest
	}
	
	public static func mainFolder() -> URL? {
		guard let dest = SPFileManager.fullPathOfFile(fileName: Folder.main.rawValue, isDirectory: true) else {
			return nil
		}
		if self.default.existence(atUrl: dest) != .directory {
			do {
				try self.default.createDirectory(at: dest, withIntermediateDirectories: false, attributes: nil)
			} catch {
				return nil
			}
		}
		return dest
	}
}
