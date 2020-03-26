
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
	
	func image( for index:Int) -> UIImage? {
		return dataSource.image(for: index)
	}
	
	func index(from indexPath:IndexPath?) -> Int {
		guard let indexPath = indexPath else {
			return 0
		}
		return dataSource.index(for: indexPath)
	}
}
