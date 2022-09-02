import Foundation
import UIKit

public class STConstants {
    
    public static var minFreeDiskUnits: STBytesUnits = STBytesUnits(mb: 500)
	
    public static func thumbSize(for originalSize: CGSize) -> CGSize {
        let targetSize = CGSize(width: 800, height: 800)
        let scale = min((targetSize.width / originalSize.width), (targetSize.height / originalSize.height))
        return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
	}    
	
}
