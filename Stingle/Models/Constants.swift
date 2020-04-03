import Foundation
import UIKit

class UIConstants {
	static func thumbSize (for originalSize:CGSize) -> CGSize {
		let screenSize: CGRect = UIScreen.main.bounds
		let width = (screenSize.size.width * originalSize.width) / (screenSize.size.width + originalSize.width)
		let ratio:CGFloat = originalSize.height / originalSize.width
		let height = width * ratio
		return CGSize(width: width, height: height)
	}
}
