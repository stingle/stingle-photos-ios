//
//  STFlipable.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

protocol STFlipable {
    func flip(directionHorizontal: Bool)
}

extension STFlipable where Self: STCropperVC {
    func flip(directionHorizontal: Bool = true) {
        let size: CGSize = self.scrollView.contentSize
        let contentOffset = self.scrollView.contentOffset
        let bounds: CGSize = self.scrollView.bounds.size

        self.scrollView.contentOffset = CGPoint(x: size.width - bounds.width - contentOffset.x, y: contentOffset.y)

        let image = self.imageView.image
        let fliped: Bool = (image?.imageOrientation == .upMirrored)

        if directionHorizontal {
            self.flipAngle += -2.0 * self.totalAngle // Make sum equal to -self.totalAngle
        } else {
            self.flipAngle += CGFloat.pi - 2.0 * self.totalAngle //  Make sum equal to pi - self.totalAngle
        }

        self.imageView.image = image?.withOrientation(fliped ? .up : .upMirrored)

        self.scrollView.transform = CGAffineTransform(rotationAngle: self.totalAngle)
    }
}
