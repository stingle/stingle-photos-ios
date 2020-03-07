import Foundation


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
	
	public static func moveToHomeFolder(fileURL:URL?, withName:String?) throws -> Bool {
		//TODO : Throw exception
		guard let fileURL = fileURL, let name = withName else {
			return false
		}
		guard let dest = SPFileManager.fullPathOfFile(fileName: name) else {
			return false
		}
		do {
			try self.default.moveItem(at: fileURL, to: dest)
		} catch {
			throw error
		}
		return true
	}
	
	public static func fullPathOfFile(fileName:String) -> URL? {
		guard let fullPath = (SPFileManager.storagePath?.appendingPathComponent(fileName)) else {
			return nil
		}
		return fullPath
	}
}
