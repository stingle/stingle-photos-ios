//
//  STRotatable.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

protocol STRotatable {
    func setStraightenAngle(_ angle: CGFloat)
    func rotate90degrees(clockwise: Bool, completion: (() -> Void)?)
}

extension STRotatable where Self: STCropperViewController {
    func setStraightenAngle(_ angle: CGFloat) {
        self.overlayView.cropBoxFrame = self.overlayView.cropBoxFrame
        self.overlayView.gridLinesAlpha = 1
        self.overlayView.gridLinesCount = 8

        UIView.animate(withDuration: 0.2, animations: {
            self.overlayView.blur = false
        })

        self.straightenAngle = angle
        self.scrollView.transform = CGAffineTransform(rotationAngle: self.totalAngle)

        let rect = self.overlayView.cropBoxFrame
        let rotatedRect = rect.applying(CGAffineTransform(rotationAngle: self.totalAngle))
        let width = rotatedRect.size.width
        let height = rotatedRect.size.height
        let center = self.scrollView.center

        let contentOffset = self.scrollView.contentOffset
        let contentOffsetCenter = CGPoint(x: contentOffset.x + self.scrollView.bounds.size.width / 2, y: contentOffset.y + scrollView.bounds.size.height / 2)
        self.scrollView.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let newContentOffset = CGPoint(x: contentOffsetCenter.x - self.scrollView.bounds.size.width / 2, y: contentOffsetCenter.y - self.scrollView.bounds.size.height / 2)
        self.scrollView.contentOffset = newContentOffset
        self.scrollView.center = center

        let shouldScale: Bool = self.scrollView.contentSize.width / self.scrollView.bounds.size.width <= 1.0 || self.scrollView.contentSize.height / self.scrollView.bounds.size.height <= 1.0
        if !self.manualZoomed || shouldScale {
            self.scrollView.minimumZoomScale = self.scrollViewZoomScaleToBounds()
            self.scrollView.setZoomScale(self.scrollViewZoomScaleToBounds(), animated: false)

            self.manualZoomed = false
        } else if self.straightenAngle == 0.0 {
            self.scrollView.minimumZoomScale = 1.0
        }

        self.scrollView.contentOffset = self.safeContentOffsetForScrollView(newContentOffset)
    }

    func rotate90degrees(clockwise: Bool = true, completion: (() -> Void)? = nil) {
        guard let animationContainer = self.scrollView.superview else { return }

        // Make sure to cover the entire screen while rotating
        let scale = max(self.maxCropRegion.size.width / self.overlayView.cropBoxFrame.size.width, self.maxCropRegion.size.height / self.overlayView.cropBoxFrame.size.height)
        let frame = animationContainer.bounds.insetBy(dx: -animationContainer.width * scale * 3, dy: -animationContainer.height * scale * 3)

        let rotatingOverlay = STOverlay(frame: frame)
        rotatingOverlay.blur = false
        rotatingOverlay.maskColor = self.backgroundView.backgroundColor ?? .black
        rotatingOverlay.cropBoxAlpha = 0
        animationContainer.addSubview(rotatingOverlay)

        let rotatingCropBoxFrame = rotatingOverlay.convert(self.overlayView.cropBoxFrame, from: self.backgroundView)
        rotatingOverlay.cropBoxFrame = rotatingCropBoxFrame
        rotatingOverlay.transform = .identity
        rotatingOverlay.layer.anchorPoint = CGPoint(x: rotatingCropBoxFrame.midX / rotatingOverlay.size.width, y: rotatingCropBoxFrame.midY / rotatingOverlay.size.height)

        self.overlayView.isHidden = true

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            // rotate scroll view
            if clockwise {
                self.rotationAngle += CGFloat.pi / 2.0
            } else {
                self.rotationAngle -= CGFloat.pi / 2.0
            }
            self.rotationAngle = self.standardizeAngle(self.rotationAngle)
            self.scrollView.transform = CGAffineTransform(rotationAngle: self.totalAngle)

            // position scroll view
            let scrollViewCenter = self.scrollView.center
            let cropBoxCenter = self.defaultCropBoxCenter
            let r = self.overlayView.cropBoxFrame
            var rect: CGRect = .zero

            let scaleX = self.maxCropRegion.size.width / r.size.height
            let scaleY = self.maxCropRegion.size.height / r.size.width

            let scale = min(scaleX, scaleY)

            rect.size.width = r.size.height * scale
            rect.size.height = r.size.width * scale

            rect.origin.x = cropBoxCenter.x - rect.size.width / 2.0
            rect.origin.y = cropBoxCenter.y - rect.size.height / 2.0

            self.overlayView.cropBoxFrame = rect

            rotatingOverlay.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0).scaledBy(x: scale, y: scale)
            rotatingOverlay.center = scrollViewCenter

            let rotatedRect = rect.applying(CGAffineTransform(rotationAngle: self.totalAngle))
            let width = rotatedRect.size.width
            let height = rotatedRect.size.height

            let contentOffset = self.scrollView.contentOffset
            let showingContentCenter = CGPoint(x: contentOffset.x + self.scrollView.bounds.size.width / 2, y: contentOffset.y + self.scrollView.bounds.size.height / 2)
            let showingContentNormalizedCenter = CGPoint(x: showingContentCenter.x / self.imageView.width, y: showingContentCenter.y / self.imageView.height)

            self.scrollView.bounds = CGRect(x: 0, y: 0, width: width, height: height)
            let zoomScale = self.scrollView.zoomScale * scale
            self.willSetScrollViewZoomScale(zoomScale)
            self.scrollView.zoomScale = zoomScale
            let newContentOffset = CGPoint(x: showingContentNormalizedCenter.x * self.imageView.width - self.scrollView.bounds.size.width * 0.5,
                                           y: showingContentNormalizedCenter.y * self.imageView.height - self.scrollView.bounds.size.height * 0.5)
            self.scrollView.contentOffset = self.safeContentOffsetForScrollView(newContentOffset)
            self.scrollView.center = scrollViewCenter
        }, completion: { _ in
            self.aspectRatioView.rotateAspectRatios()
            self.overlayView.cropBoxAlpha = 0
            self.overlayView.blur = true
            self.overlayView.isHidden = false
            completion?()
            UIView.animate(withDuration: 0.25, animations: {
                rotatingOverlay.alpha = 0
                self.overlayView.cropBoxAlpha = 1
            }, completion: { _ in
                rotatingOverlay.isHidden = true
                rotatingOverlay.removeFromSuperview()
            })
        })
    }
}
