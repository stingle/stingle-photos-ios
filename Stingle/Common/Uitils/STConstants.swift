import Foundation
import UIKit

class STConstants {
	
	static func thumbSize(for originalSize: CGSize) -> CGSize {
        let targetSize = CGSize(width: 800, height: 800)
        let scale = min((targetSize.width / originalSize.width), (targetSize.height / originalSize.height))
        return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
	}
	
}
