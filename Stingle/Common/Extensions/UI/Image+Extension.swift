import Foundation
import UIKit

extension UIImage {
	
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
	
	func scale(to width: CGFloat) -> UIImage? {
		let scale =  width / CGFloat(size.width)
		let h = size.height * scale
		let w = size.width * scale
		let newRect = CGRect(x: 0, y: 0, width: w, height: h)
		UIGraphicsBeginImageContext(newRect.size)
		UIImage(cgImage: cgImage!).draw(in: newRect)
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}

    func scaled(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self

    }

}
