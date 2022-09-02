//
//  AVAsset+Helper.swift
//  StingleRoot
//
//  Created by Khoren Asatryan on 17.07.22.
//

import UIKit
import AVFoundation

public extension AVAsset {
    
    func videoSize() -> CGSize? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else {
            return nil
        }
        let size = track.naturalSize
        let txf = track.preferredTransform
        let realVidSize = size.applying(txf)
        return realVidSize
    }
    
    func generateThumbnailFromAsset(forTime time: CMTime) throws -> UIImage {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        var actualTime: CMTime = .zero
        let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
        let image = UIImage(cgImage: imageRef)
        return image
    }
    
    func generateThumbnailFromAsset(forTime time: TimeInterval) throws -> UIImage {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000000)
        return try self.generateThumbnailFromAsset(forTime: cmTime)
    }
    
}
