//
//  STCropperVC+Additional.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/29/22.
//

import UIKit

extension STCropperVC {
    
    // Make angle in 0 - 360 degrees
    func standardizeAngle(_ angle: CGFloat) -> CGFloat {
        var angle = angle
        if angle >= 0, angle <= 2 * CGFloat.pi {
            return angle
        } else if angle < 0 {
            angle += 2 * CGFloat.pi

            return self.standardizeAngle(angle)
        } else {
            angle -= 2 * CGFloat.pi

            return self.standardizeAngle(angle)
        }
    }

    func autoHorizontalOrVerticalAngle(_ angle: CGFloat) -> CGFloat {
        var angle = angle
        angle = self.standardizeAngle(angle)

        let deviation: CGFloat = 0.017444444 // 1 * 3.14 / 180, sync with AngleRuler
        if abs(angle - 0) < deviation {
            angle = 0
        } else if abs(angle - CGFloat.pi / 2.0) < deviation {
            angle = CGFloat.pi / 2.0
        } else if abs(angle - CGFloat.pi) < deviation {
            angle = CGFloat.pi - 0.001 // Handling a iOS bug that causes problems with rotation animations
        } else if abs(angle - CGFloat.pi / 2.0 * 3) < deviation {
            angle = CGFloat.pi / 2.0 * 3
        } else if abs(angle - CGFloat.pi * 2) < deviation {
            angle = CGFloat.pi * 2
        }

        return angle
    }

}

extension STCropperVC {
    
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

    func rotate90degrees(clockwise: Bool = true, animation: Bool = true, completion: (() -> Void)? = nil) {
        guard let animationContainer = self.scrollView.superview else { return }

        // Make sure to cover the entire screen while rotating
        let scale = max(self.maxCropRegion.size.width / self.overlayView.cropBoxFrame.size.width, self.maxCropRegion.size.height / self.overlayView.cropBoxFrame.size.height)
        let frame = animationContainer.bounds.insetBy(dx: -animationContainer.width * scale * 3, dy: -animationContainer.height * scale * 3)

        let rotatingOverlay = STCropOverlay(frame: frame)
        rotatingOverlay.blur = false
        rotatingOverlay.maskColor = self.backgroundView.backgroundColor ?? .black
        rotatingOverlay.cropBoxAlpha = 0
        animationContainer.addSubview(rotatingOverlay)

        let rotatingCropBoxFrame = rotatingOverlay.convert(self.overlayView.cropBoxFrame, from: self.backgroundView)
        rotatingOverlay.cropBoxFrame = rotatingCropBoxFrame
        rotatingOverlay.transform = .identity
        rotatingOverlay.layer.anchorPoint = CGPoint(x: rotatingCropBoxFrame.midX / rotatingOverlay.size.width, y: rotatingCropBoxFrame.midY / rotatingOverlay.size.height)

        self.overlayView.isHidden = true
        let duration = animation ? 0.25 : 0.0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
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

extension STCropperVC {
    
    func isCurrentlyInState(_ state: CropperState?) -> Bool {
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

    func saveState() -> CropperState {
        let cs = CropperState(viewFrame: self.view.frame,
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

    func restoreState(_ state: CropperState, animated: Bool = false) {
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

extension STCropperVC {
    
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

extension STCropperVC {
    
    func nearestCropBoxEdgeForPoint(point: CGPoint) -> STCropBoxEdge {
        var frame = self.overlayView.cropBoxFrame

        frame = frame.insetBy(dx: -self.cropBoxHotArea / 2.0, dy: -self.cropBoxHotArea / 2.0)

        let topLeftRect = CGRect(origin: frame.origin, size: CGSize(width: self.cropBoxHotArea, height: self.cropBoxHotArea))

        if topLeftRect.contains(point) {
            return .topLeft
        }

        var topRightRect = topLeftRect
        topRightRect.origin.x = frame.maxX - self.cropBoxHotArea
        if topRightRect.contains(point) {
            return .topRight
        }

        var bottomLeftRect = topLeftRect
        bottomLeftRect.origin.y = frame.maxY - self.cropBoxHotArea
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }

        var bottomRightRect = topRightRect
        bottomRightRect.origin.y = bottomLeftRect.origin.y
        if bottomRightRect.contains(point) {
            return .bottomRight
        }

        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: self.cropBoxHotArea))
        if topRect.contains(point) {
            return .top
        }

        var bottomRect = topRect
        bottomRect.origin.y = frame.maxY - self.cropBoxHotArea
        if bottomRect.contains(point) {
            return .bottom
        }

        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: self.cropBoxHotArea, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }

        var rightRect = leftRect
        rightRect.origin.x = frame.maxX - self.cropBoxHotArea
        if rightRect.contains(point) {
            return .right
        }

        return .none
    }

    func updateCropBoxFrameWithPanGesturePoint(_ point: CGPoint) {
        var point = point
        var frame = self.overlayView.cropBoxFrame
        let originFrame = self.panBeginningCropBoxFrame
        let contentFrame = self.maxCropRegion

        point.x = max(contentFrame.origin.x, point.x)
        point.y = max(contentFrame.origin.y, point.y)

        // The delta between where we first tapped, and where our finger is now
        var xDelta = (point.x - self.panBeginningPoint.x)
        var yDelta = (point.y - self.panBeginningPoint.y)

        let aspectRatio = self.currentAspectRatioValue

        var panHorizontal: Bool = false
        var panVertical: Bool = false

        switch self.panBeginningCropBoxEdge {
        case .left:
            frame.origin.x = originFrame.origin.x + xDelta
            frame.size.width = max(self.cropBoxMinSize, originFrame.size.width - xDelta)
            if self.aspectRatioLocked {
                panHorizontal = true
                xDelta = max(xDelta, 0)
                let scaleOrigin = CGPoint(x: originFrame.maxX, y: originFrame.midY)
                frame.size.height = frame.size.width / aspectRatio
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5)
            }

        case .right:
            if self.aspectRatioLocked {
                panHorizontal = true
                frame.size.width = max(self.cropBoxMinSize, originFrame.size.width + xDelta)
                frame.size.width = min(frame.size.width, contentFrame.size.height * aspectRatio)
                let scaleOrigin = CGPoint(x: originFrame.minX, y: originFrame.midY)
                frame.size.height = frame.size.width / aspectRatio
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5)
            } else {
                frame.size.width = originFrame.size.width + xDelta
            }

        case .bottom:
            if self.aspectRatioLocked {
                panVertical = true
                frame.size.height = max(self.cropBoxMinSize, originFrame.size.height + yDelta)
                frame.size.height = min(frame.size.height, contentFrame.size.width / aspectRatio)
                let scaleOrigin = CGPoint(x: originFrame.midX, y: originFrame.minY)
                frame.size.width = frame.size.height * aspectRatio
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5)
            } else {
                frame.size.height = originFrame.size.height + yDelta
            }

        case .top:
            if self.aspectRatioLocked {
                panVertical = true
                yDelta = max(0, yDelta)
                frame.origin.y = originFrame.origin.y + yDelta
                frame.size.height = max(self.cropBoxMinSize, originFrame.size.height - yDelta)
                let scaleOrigin = CGPoint(x: originFrame.midX, y: originFrame.maxY)
                frame.size.width = frame.size.height * aspectRatio
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5)
            } else {
                frame.origin.y = originFrame.origin.y + yDelta
                frame.size.height = originFrame.size.height - yDelta
            }

        case .topLeft:
            if self.aspectRatioLocked {
                xDelta = max(xDelta, 0)
                yDelta = max(yDelta, 0)

                var distance = CGPoint()
                distance.x = 1.0 - (xDelta / originFrame.width)
                distance.y = 1.0 - (yDelta / originFrame.height)

                let scale = (distance.x + distance.y) * 0.5

                frame.size.width = (originFrame.width * scale)
                frame.size.height = (originFrame.height * scale)
                frame.origin.x = originFrame.origin.x + (originFrame.width - frame.size.width)
                frame.origin.y = originFrame.origin.y + (originFrame.height - frame.size.height)

                panVertical = true
                panHorizontal = true
            } else {
                frame.origin.x = originFrame.origin.x + xDelta
                frame.size.width = originFrame.size.width - xDelta
                frame.origin.y = originFrame.origin.y + yDelta
                frame.size.height = originFrame.size.height - yDelta
            }

        case .topRight:
            if self.aspectRatioLocked {
                xDelta = max(xDelta, 0)
                yDelta = max(yDelta, 0)

                var distance = CGPoint()
                distance.x = 1.0 - ((-xDelta) / originFrame.width)
                distance.y = 1.0 - (yDelta / originFrame.height)

                var scale = (distance.x + distance.y) * 0.5
                scale = min(1.0, scale)

                frame.size.width = (originFrame.width * scale)
                frame.size.height = (originFrame.height * scale)
                frame.origin.y = originFrame.maxY - frame.size.height

                panVertical = true
                panHorizontal = true
            } else {
                frame.size.width = originFrame.size.width + xDelta
                frame.origin.y = originFrame.origin.y + yDelta
                frame.size.height = originFrame.size.height - yDelta
            }

        case .bottomLeft:
            if self.aspectRatioLocked {
                var distance = CGPoint()
                distance.x = 1.0 - (xDelta / originFrame.width)
                distance.y = 1.0 - (-yDelta / originFrame.height)

                let scale = (distance.x + distance.y) * 0.5

                frame.size.width = (originFrame.width * scale)
                frame.size.height = (originFrame.height * scale)
                frame.origin.x = originFrame.maxX - frame.size.width

                panVertical = true
                panHorizontal = true
            } else {
                frame.size.height = originFrame.size.height + yDelta
                frame.origin.x = originFrame.origin.x + xDelta
                frame.size.width = originFrame.size.width - xDelta
            }

        case .bottomRight:
            if self.aspectRatioLocked {
                var distance = CGPoint()
                distance.x = 1.0 - ((-1 * xDelta) / originFrame.width)
                distance.y = 1.0 - ((-1 * yDelta) / originFrame.height)

                let scale = (distance.x + distance.y) * 0.5

                frame.size.width = (originFrame.width * scale)
                frame.size.height = (originFrame.height * scale)

                panVertical = true
                panHorizontal = true
            } else {
                frame.size.height = originFrame.size.height + yDelta
                frame.size.width = originFrame.size.width + xDelta
            }

        case .none:
            break
        }

        // Work out the limits the box may be scaled before it starts to overlap itself
        var minSize: CGSize = .zero
        minSize.width = self.cropBoxMinSize
        minSize.height = self.cropBoxMinSize

        var maxSize: CGSize = .zero
        maxSize.width = contentFrame.width
        maxSize.height = contentFrame.height

        // clamp the box to ensure it doesn't go beyond the bounds we've set
        if self.aspectRatioLocked, panHorizontal {
            maxSize.height = contentFrame.size.width / aspectRatio
            if aspectRatio > 1 {
                minSize.width = self.cropBoxMinSize * aspectRatio
            } else {
                minSize.height = self.cropBoxMinSize / aspectRatio
            }
        }

        if self.aspectRatioLocked, panVertical {
            maxSize.width = contentFrame.size.height * aspectRatio
            if aspectRatio > 1 {
                minSize.width = self.cropBoxMinSize * aspectRatio
            } else {
                minSize.height = self.cropBoxMinSize / aspectRatio
            }
        }

        // Clamp the minimum size
        frame.size.width = max(frame.size.width, minSize.width)
        frame.size.height = max(frame.size.height, minSize.height)

        // Clamp the maximum size
        frame.size.width = min(frame.size.width, maxSize.width)
        frame.size.height = min(frame.size.height, maxSize.height)

        frame.origin.x = max(frame.origin.x, contentFrame.minX)
        frame.origin.x = min(frame.origin.x, contentFrame.maxX - minSize.width)
        frame.origin.x = min(frame.origin.x, originFrame.maxX - minSize.width) // Cannot pan the left side of the box out of the right area of the previous box

        frame.origin.y = max(frame.origin.y, contentFrame.minY)
        frame.origin.y = min(frame.origin.y, contentFrame.maxY - minSize.height)
        frame.origin.y = min(frame.origin.y, originFrame.maxY - minSize.height) // Cannot pan the top of the box out of the bottom area of the previous frame

        self.cropBoxFrame = frame
    }

}

extension STCropperVC {
    
    func stasisAndThenRun(_ closure: @escaping () -> Void) {
        self.cancelStasis()
        self.stasisTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.view.isUserInteractionEnabled = false
            if self?.stasisThings != nil {
                self?.stasisThings?()
            }
            self?.cancelStasis()
        })
        self.stasisThings = closure
    }

    func cancelStasis() {
        guard self.stasisTimer != nil else {
            return
        }
        self.stasisTimer?.invalidate()
        self.stasisTimer = nil
        self.stasisThings = nil
        self.view.isUserInteractionEnabled = true
    }

}

extension STCropperVC {
    
    func setAspectRatio(_ aspectRatio: AspectRatio, animated: Bool = true) {
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
