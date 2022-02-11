//
//  STCropperState.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

struct STCropperState: Codable {
    var viewFrame: CGRect
    var angle: CGFloat
    var rotationAngle: CGFloat
    var straightenAngle: CGFloat
    var flipAngle: CGFloat
    var imageOrientationRawValue: Int
    var scrollViewTransform: CGAffineTransform
    var scrollViewCenter: CGPoint
    var scrollViewBounds: CGRect
    var scrollViewContentOffset: CGPoint
    var scrollViewMinimumZoomScale: CGFloat
    var scrollViewMaximumZoomScale: CGFloat
    var scrollViewZoomScale: CGFloat
    var cropBoxFrame: CGRect
    var photoTranslation: CGPoint
    var imageViewTransform: CGAffineTransform
    var imageViewBoundsSize: CGSize
}
