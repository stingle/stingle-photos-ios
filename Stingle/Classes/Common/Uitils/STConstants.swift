import Foundation
import UIKit

class STConstants {
	
	static func thumbSize (for originalSize:CGSize) -> CGSize {
		let screenSize: CGRect = UIScreen.main.bounds
		let width = (screenSize.size.width * originalSize.width) / (screenSize.size.width + originalSize.width)
		let scale:CGFloat = originalSize.width / width
		let height = originalSize.height / scale
		return CGSize(width: width, height: height)
	}
	
}
