//
//  STAspectRatioSettable.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

protocol STAspectRatioSettable {
    func setAspectRatio(_ aspectRatio: STAspectRatio, animated: Bool)
    func setAspectRatioValue(_ aspectRatioValue: CGFloat, animated: Bool)
}

extension STAspectRatioSettable where Self: STCropperViewController {
    func setAspectRatio(_ aspectRatio: STAspectRatio, animated: Bool = true) {
        switch aspectRatio {
        case .original:
            var width: CGFloat
            var height: CGFloat
            let angle = self.standardizeAngle(self.rotationAngle)
            if angle.isEqual(to: .pi / 2.0, accuracy: 0.001) || angle.isEqual(to: .pi * 1.5, accuracy: 0.001) {
                width = self.originalImage.size.height
                height = self.originalImage.size.width
            } else {
                width = self.originalImage.size.width
                height = self.originalImage.size.height
            }

            if self.aspectRatioView.rotated {
                swap(&width, &height)
            }

            if width > height {
                self.aspectRatioView.selectedBox = .horizontal
            } else if width < height {
                self.aspectRatioView.selectedBox = .vertical
            } else {
                self.aspectRatioView.selectedBox = .none
            }
            self.setAspectRatioValue(width / height, animated: animated)
            self.aspectRatioLocked = true
        case .freeForm:
            self.aspectRatioView.selectedBox = .none
            self.aspectRatioLocked = false
        case .square:
            self.aspectRatioView.selectedBox = .none
            self.setAspectRatioValue(1, animated: animated)
            self.aspectRatioLocked = true
        case let .ratio(width, height):
            if width > height {
                self.aspectRatioView.selectedBox = .horizontal
            } else if width < height {
                self.aspectRatioView.selectedBox = .vertical
            } else {
                self.aspectRatioView.selectedBox = .none
            }
            self.setAspectRatioValue(CGFloat(width) / CGFloat(height), animated: animated)
            self.aspectRatioLocked = true
        }
    }

    func setAspectRatioValue(_ aspectRatioValue: CGFloat, animated: Bool) {
        guard aspectRatioValue > 0 else { return }

        self.aspectRatioLocked = true
        self.currentAspectRatioValue = aspectRatioValue

        var targetCropBoxFrame: CGRect
        let height: CGFloat = self.maxCropRegion.size.width / aspectRatioValue
        if height <= self.maxCropRegion.size.height {
            targetCropBoxFrame = CGRect(center: self.defaultCropBoxCenter, size: CGSize(width: self.maxCropRegion.size.width, height: height))
        } else {
            let width = self.maxCropRegion.size.height * aspectRatioValue
            targetCropBoxFrame = CGRect(center: self.defaultCropBoxCenter, size: CGSize(width: width, height: self.maxCropRegion.size.height))
        }
        targetCropBoxFrame = self.safeCropBoxFrame(targetCropBoxFrame)

        let currentCropBoxFrame = self.overlayView.cropBoxFrame

        /// The content of the image is getting bigger and bigger when switching the aspect ratio.
        /// Make a fake cropBoxFrame to help calculate how much the image should be scaled.
        var contentBiggerThanCurrentTargetCropBoxFrame: CGRect
        if currentCropBoxFrame.size.width / currentCropBoxFrame.size.height > aspectRatioValue {
            contentBiggerThanCurrentTargetCropBoxFrame = CGRect(center: self.defaultCropBoxCenter, size: CGSize(width: currentCropBoxFrame.size.width, height: currentCropBoxFrame.size.width / aspectRatioValue))
        } else {
            contentBiggerThanCurrentTargetCropBoxFrame = CGRect(center: self.defaultCropBoxCenter, size: CGSize(width: currentCropBoxFrame.size.height * aspectRatioValue, height: currentCropBoxFrame.size.height))
        }
        let extraZoomScale = max(targetCropBoxFrame.size.width / contentBiggerThanCurrentTargetCropBoxFrame.size.width, targetCropBoxFrame.size.height / contentBiggerThanCurrentTargetCropBoxFrame.size.height)

        self.overlayView.gridLinesAlpha = 0

        self.matchScrollViewAndCropView(animated: animated, targetCropBoxFrame: targetCropBoxFrame, extraZoomScale: extraZoomScale, blurLayerAnimated: animated)
    }
}
