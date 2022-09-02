import Foundation
import UIKit

public extension UIImage {
    
    var thumbnail: UIImage {
        let size = STConstants.thumbSize(for: CGSize(width: self.size.width, height: self.size.height))
        let thumb = self.scaled(newSize: size)
        return thumb
    }
    
    var thumbnailData: Data? {
        guard let thumbData = self.thumbnail.jpegData(compressionQuality: 0.7)  else {
            return nil
        }
        return thumbData
    }
    
	func resize(size: CGSize) -> UIImage? {
		
		//Calculate x and y positions and edge size for cropping
		let originalSize = self.size
		var x:CGFloat = 0.0
		var y:CGFloat = 0.0
		let w = originalSize.width
		let h = originalSize.height
		let rectSize = min(w, h)
		if w > h {
			x = (w - h) / 2
			y = 0
		} else {
			x = 0
			y = (h - w) / 2
		}
		
		//Crope image to square
		guard let cgImage = self.cgImage else {
			return nil
		}
		let rect = CGRect(x: x, y: y, width: rectSize, height: rectSize)
		let croppedCGImage = cgImage.cropping(to: rect)
		
		//Resize cropped image to prefered size
		let newRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
		UIImage(cgImage: croppedCGImage!).draw(in: newRect)
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
	
	func scale(to width: CGFloat) -> UIImage {
        let scale =  width / CGFloat(self.size.width)
        let h = self.size.height * scale
        let w = self.size.width * scale
        return self.scaled(newSize: CGSize(width: w, height: h))
	}

    func scaled(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }

}
