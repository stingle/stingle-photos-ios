
import Foundation
import UIKit

class SPImagePreviewVM {
	
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

	
	func index(from indexPath:IndexPath?) -> Int {
		guard let indexPath = indexPath else {
			return 0
		}
		return dataSource.index(for: indexPath)
	}
}
