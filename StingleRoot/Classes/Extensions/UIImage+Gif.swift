//
//  UIImage+Gif.swift
//  Stingle
//
//  Created by Khoren Asatryan on 27.06.22.
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

extension UIImage {
    
    class func gif(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            STLogger.log(info: "SwiftGif: Source for the image does not exist")
            return nil
        }
        return UIImage.animatedImageWithSource(source)
    }
    
    class func gif(url: String) -> UIImage? {
        guard let bundleURL = URL(string: url) else {
            STLogger.log(info: "SwiftGif: This image named \"\(url)\" does not exist")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            STLogger.log(info: "SwiftGif: Cannot turn image named \"\(url)\" into NSData")
            return nil
        }
        return self.gif(data: imageData)
    }
    
    class func gif(name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
            STLogger.log(info: "SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            STLogger.log(info: "SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        return self.gif(data: imageData)
    }
    
    //MARK: - Private methods
    
    private class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }
        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()), to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as? Double ?? 0
        return delay
    }
    
    private class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        if a! < b! {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        
        while true {
            rest = a! % b!
            if rest == 0 {
                return b! // Found it
            } else {
                a = b
                b = rest
            }
        }
    }
    
    private class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        var gcd = array[0]
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    private class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i), source: source)
            delays.append(Int(delaySeconds * 1000.0))
        }
        
        // Calculate full duration
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        let animation = UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
        return animation
    }
    
}

public extension UIImage {
    
    func imageData(for type: UTType) -> Data? {
        var cgImage = self.cgImage
        if cgImage == nil, let ciImage = self.ciImage {
            cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        }
        guard
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, type.identifier as CFString, 1, nil),
            let cgImage = cgImage
        else {
            return nil
        }
        let cgImageOrientation = CGImagePropertyOrientation(self.imageOrientation)
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: 1.0, kCGImagePropertyOrientation: cgImageOrientation.rawValue] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return mutableData as Data
    }

}

public extension UTType {
    
    var headerFileType: STHeader.FileType? {
        switch self {
        case .heic, .rawImage, .tiff, .gif, .heif, .svg, .ico, .jpeg, .image, .png, .icns, .bmp, .livePhoto, .webP:
            return .image
        case .avi, .appleProtectedMPEG4Video, .quickTimeMovie, .movie, .mpeg4Movie, .mpeg2Video, .mpeg, .video:
            return .image
        default:
            return nil
        }
    }

}

