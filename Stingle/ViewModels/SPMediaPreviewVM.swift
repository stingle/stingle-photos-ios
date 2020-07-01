
import Foundation
import UIKit

class SPMediaPreviewVM {
	
	private let dataSource:DataSource
	
	init(dataSource:DataSource) {
		self.dataSource = dataSource
	}
	
	func numberOfPages () -> Int {
		return dataSource.numberOfFiles()
	}
	
	func thumb( for index:Int) -> UIImage? {
		guard let image = dataSource.thumb(index: index) else {
			return nil
		}
		return image
	}

	func image( for index:Int,completionHandler:  @escaping (UIImage?) -> Swift.Void) {
		dataSource.image(index: index) { image in
			completionHandler(image)
		}
	}
	
//	func video( for index:Int, from offset:UInt64, size:UInt, completionHandler:  @escaping (URL?, [UInt8]?, Error?) -> Swift.Void) {
//		dataSource.video(index: index,  from: offset, size: size) {(url, data, error) in
//			completionHandler(url, data, error)
//		}
//	}


	func trashSelected(index:Int) {
		guard let file = dataSource.file(for: index) else {
			return
		}
		_ = SyncManager.moveFiles(files: [file], from: .Gallery, to: .Trash) { error in
			if let error = error {
				print(error)
			}
		}
	}
	
	func file(for index:Int) -> SPFileInfo? {
		return dataSource.file(for: index)
	}

	func index(from indexPath:IndexPath?) -> Int {
		guard let indexPath = indexPath else {
			return 0
		}
		return dataSource.index(for: indexPath)
	}
}
