//
//  STStateRestorable.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

protocol STStateRestorable {
    func isCurrentlyInState(_ state: STCropperState?) -> Bool
    func saveState() -> STCropperState
    func restoreState(_ state: STCropperState, animated: Bool)
}

extension STStateRestorable where Self: STCropperVC {
    func isCurrentlyInState(_ state: STCropperState?) -> Bool {
        guard let state = state else { return false }
        let epsilon: CGFloat = 0.0001

        if state.viewFrame.isEqual(to: view.frame, accuracy: epsilon),
           state.angle.isEqual(to: totalAngle, accuracy: epsilon),
           state.rotationAngle.isEqual(to: rotationAngle, accuracy: epsilon),
           state.straightenAngle.isEqual(to: straightenAngle, accuracy: epsilon),
           state.flipAngle.isEqual(to: flipAngle, accuracy: epsilon),
           state.imageOrientationRawValue == imageView.image?.imageOrientation.rawValue ?? 0,
           state.scrollViewTransform.isEqual(to: scrollView.transform, accuracy: epsilon),
           state.scrollViewCenter.isEqual(to: scrollView.center, accuracy: epsilon),
           state.scrollViewBounds.isEqual(to: scrollView.bounds, accuracy: epsilon),
           state.scrollViewContentOffset.isEqual(to: scrollView.contentOffset, accuracy: epsilon),
           state.scrollViewMinimumZoomScale.isEqual(to: scrollView.minimumZoomScale, accuracy: epsilon),
           state.scrollViewMaximumZoomScale.isEqual(to: scrollView.maximumZoomScale, accuracy: epsilon),
           state.scrollViewZoomScale.isEqual(to: scrollView.zoomScale, accuracy: epsilon),
           state.cropBoxFrame.isEqual(to: self.overlayView.cropBoxFrame, accuracy: epsilon) {
            return true
        }

        return false
    }

    func saveState() -> STCropperState {
        let cs = STCropperState(viewFrame: self.view.frame,
                              angle: self.totalAngle,
                              rotationAngle: self.rotationAngle,
                              straightenAngle: self.straightenAngle,
                              flipAngle: self.flipAngle,
                              imageOrientationRawValue: self.imageView.image?.imageOrientation.rawValue ?? 0,
                              scrollViewTransform: self.scrollView.transform,
                              scrollViewCenter: self.scrollView.center,
                              scrollViewBounds: self.scrollView.bounds,
                              scrollViewContentOffset: self.scrollView.contentOffset,
                              scrollViewMinimumZoomScale: self.scrollView.minimumZoomScale,
                              scrollViewMaximumZoomScale: self.scrollView.maximumZoomScale,
                              scrollViewZoomScale: self.scrollView.zoomScale,
                              cropBoxFrame: self.overlayView.cropBoxFrame,
                              photoTranslation: self.photoTranslation(),
                              imageViewTransform: self.imageView.transform,
                              imageViewBoundsSize: self.imageView.bounds.size)
        return cs
    }

    func restoreState(_ state: STCropperState, animated: Bool = false) {
        guard self.view.frame.equalTo(state.viewFrame) else {
            return
        }

        let animationsBlock = { () -> Void in
            self.rotationAngle = state.rotationAngle
            self.straightenAngle = state.straightenAngle
            self.flipAngle = state.flipAngle
            let orientation = UIImage.Orientation(rawValue: state.imageOrientationRawValue) ?? .up
            self.imageView.image = self.imageView.image?.withOrientation(orientation)
            self.scrollView.minimumZoomScale = state.scrollViewMinimumZoomScale
            self.scrollView.maximumZoomScale = state.scrollViewMaximumZoomScale
            self.scrollView.zoomScale = state.scrollViewZoomScale
            self.scrollView.transform = state.scrollViewTransform
            self.scrollView.bounds = state.scrollViewBounds
            self.scrollView.contentOffset = state.scrollViewContentOffset
            self.scrollView.center = state.scrollViewCenter
            self.overlayView.cropBoxFrame = state.cropBoxFrame
            if self.overlayView.cropBoxFrame.size.width > self.overlayView.cropBoxFrame.size.height {
                self.aspectRatioView.aspectRatios = self.verticalAspectRatios
            } else {
                self.aspectRatioView.aspectRatios = self.verticalAspectRatios.map { $0.rotated }
            }
            self.aspectRatioView.rotated = false
            self.aspectRatioView.selectedAspectRatio = .freeForm
            self.angleRuler.value = state.straightenAngle * 180 / CGFloat.pi
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: animationsBlock)
        } else {
            animationsBlock()
        }
    }
}
