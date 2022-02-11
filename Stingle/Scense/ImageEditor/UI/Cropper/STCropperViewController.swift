//
//  STCropperViewController.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 1/17/22.
//

import UIKit

enum STCropBoxEdge: Int {
    case none
    case left
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
}

class STCropperViewController: UIViewController, STRotatable, STStateRestorable, STFlipable {

    @IBOutlet weak var scrollViewContainer: STScrollViewContainer!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var rulerValueLabel: UILabel!
    @IBOutlet weak var rulerBackgroundView: UIView!
    @IBOutlet weak var overlayView: STOverlay!
    @IBOutlet weak var aspectRatioView: STAspectRatioView!

    private var _topToolBar: STCropRotateToolBar?
    var topToolBar: UIView? {
        if self._topToolBar == nil {
            self._topToolBar = UIView.loadView(fromNib: "STCropRotateToolBar", withType: STCropRotateToolBar.self)
            self._topToolBar?.delegate = self
        }
        return self._topToolBar
    }

    lazy var angleRuler = STAngleRuler(frame: self.rulerBackgroundView.bounds)
    private var angleRulerValue: CGFloat = 0.0

    private var newCollection: UITraitCollection?

    var cropBoxFrame: CGRect {
        get {
            return self.overlayView.cropBoxFrame
        }
        set {
            self.overlayView.cropBoxFrame = self.safeCropBoxFrame(newValue)
        }
    }

    private lazy var maskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let clear = UIColor.clear.cgColor
        let black = UIColor.black.cgColor
        layer.colors = [clear, black, black, clear]
        layer.locations = [0, 0.08, 0.92, 1]
        layer.frame = self.gradientView.bounds
        if self.traitCollection.isBothCompact() || self.traitCollection.isWidthRegular() {
            layer.startPoint = CGPoint(x: 0.5, y: 0.0)
            layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        } else {
            layer.startPoint = CGPoint(x: 0.0, y: 0.5)
            layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        }
        return layer
    }()

    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.defaultCropBoxSize.width, height: self.defaultCropBoxSize.height))
        sv.delegate = self
        sv.center = self.backgroundView.convert(self.defaultCropBoxCenter, to: self.scrollViewContainer)
        sv.bounces = true
        sv.bouncesZoom = true
        sv.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sv.alwaysBounceVertical = true
        sv.alwaysBounceHorizontal = true
        sv.minimumZoomScale = 1
        sv.maximumZoomScale = 20
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.clipsToBounds = false
        sv.contentSize = self.defaultCropBoxSize
        return sv
    }()

    lazy var imageView: UIImageView = {
        let iv = UIImageView(image: self.originalImage)
        iv.backgroundColor = .clear
        return iv
    }()

    var originalImage: UIImage! {
        didSet {
            if self.isViewLoaded {
                if let image = self.imageView.image, image.imageOrientation != self.originalImage.imageOrientation {
                    guard let cgImage = self.originalImage.cgImage else {
                        self.imageView.image = self.originalImage
                        return
                    }
                    self.imageView.image = UIImage(cgImage: cgImage, scale: self.originalImage.scale, orientation: image.imageOrientation)
                } else {
                    self.imageView.image = self.originalImage
                }
            }
        }
    }

    var aspectRatioLocked: Bool = false {
        didSet {
            self.overlayView.free = !self.aspectRatioLocked
        }
    }

    var currentAspectRatioValue: CGFloat = 1.0
    var isCropBoxPanEnabled: Bool = true
    var cropContentInset: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    let cropBoxHotArea: CGFloat = 50
    let cropBoxMinSize: CGFloat = 20
    let barHeight: CGFloat = 44

    var maxCropRegion: CGRect = .zero
    var defaultCropBoxCenter: CGPoint = .zero
    var defaultCropBoxSize: CGSize = .zero

    var straightenAngle: CGFloat = 0.0
    var rotationAngle: CGFloat = 0.0
    var flipAngle: CGFloat = 0.0

    var panBeginningPoint: CGPoint = .zero
    var panBeginningCropBoxEdge: STCropBoxEdge = .none
    var panBeginningCropBoxFrame: CGRect = .zero

    var manualZoomed: Bool = false

    var stasisTimer: Timer?
    var stasisThings: (() -> Void)?

    var totalAngle: CGFloat {
        return self.autoHorizontalOrVerticalAngle(self.straightenAngle + self.rotationAngle + self.flipAngle)
    }

    lazy var cropBoxPanGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(cropBoxPan(_:)))
        pan.delegate = self
        return pan
    }()

    // MARK: Custom UI

    let verticalAspectRatios: [STAspectRatio] = [
        .original,
        .freeForm,
        .square,
        .ratio(width: 9, height: 16),
        .ratio(width: 8, height: 10),
        .ratio(width: 5, height: 7),
        .ratio(width: 3, height: 4),
        .ratio(width: 3, height: 5),
        .ratio(width: 2, height: 3)
    ]

    // MARK: - Override

    deinit {
        self.cancelStasis()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.view.clipsToBounds = false

        if self.originalImage.size.width < 1 || self.originalImage.size.height < 1 { return }

        self.scrollView.addSubview(self.imageView)
        self.scrollView.contentInsetAdjustmentBehavior = .never

        self.scrollViewContainer.scrollView = self.scrollView
        self.scrollViewContainer.addSubview(self.scrollView)

        self.scrollViewContainer.addGestureRecognizer(self.cropBoxPanGesture)
        self.scrollView.panGestureRecognizer.require(toFail: self.cropBoxPanGesture)

        self.angleRuler.minimumValue = -45
        self.angleRuler.maximumValue = 45
        self.gradientView.layer.mask = self.maskLayer
        self.angleRuler.translatesAutoresizingMaskIntoConstraints = false
        self.rulerBackgroundView.addSubview(self.angleRuler)
        NSLayoutConstraint.activate([
            self.angleRuler.leadingAnchor.constraint(equalTo: self.rulerBackgroundView.leadingAnchor),
            self.angleRuler.topAnchor.constraint(equalTo: self.rulerBackgroundView.topAnchor),
            self.angleRuler.trailingAnchor.constraint(equalTo: self.rulerBackgroundView.trailingAnchor),
            self.angleRuler.bottomAnchor.constraint(equalTo: self.rulerBackgroundView.bottomAnchor)
        ])

        self.resetToDefaultLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.originalImage.size.width < 1 || self.originalImage.size.height < 1 { return }

        if self.traitCollection.isBothCompact() || self.traitCollection.isWidthRegular() {
            self.angleRuler.setDirection(direction: .vertical)
            self.aspectRatioView.setScrollDirection(scrollDirection: .vertical)
        } else {
            self.angleRuler.setDirection(direction: .horizontal)
            self.aspectRatioView.setScrollDirection(scrollDirection: .horizontal)
        }
        self.angleRuler.value = self.angleRulerValue
        self.angleRuler.delegate = self
        self.aspectRatioView.delegate = self

        self.updateLayout()

        self.matchScrollViewAndCropView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.maskLayer.frame = self.gradientView.bounds
        if self.traitCollection.isBothCompact() || self.traitCollection.isWidthRegular() {
            self.aspectRatioView.setScrollDirection(scrollDirection: .vertical)
        } else {
            self.aspectRatioView.setScrollDirection(scrollDirection: .horizontal)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.transitionsView(with: coordinator)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.newCollection = newCollection
        self.transitionsView(with: coordinator)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .top
    }

    // MARK: - User Interaction

    @objc func cropBoxPan(_ pan: UIPanGestureRecognizer) {
        guard self.isCropBoxPanEnabled else {
            return
        }
        let point = pan.location(in: view)

        if pan.state == .began {
            self.cancelStasis()
            self.panBeginningPoint = point
            self.panBeginningCropBoxFrame = self.overlayView.cropBoxFrame
            self.panBeginningCropBoxEdge = self.nearestCropBoxEdgeForPoint(point: self.panBeginningPoint)
            self.overlayView.blur = false
            self.overlayView.gridLinesAlpha = 1
        }

        if pan.state == .ended || pan.state == .cancelled {
            self.stasisAndThenRun {
                self.matchScrollViewAndCropView(animated: true, targetCropBoxFrame: self.overlayView.cropBoxFrame, blurLayerAnimated: true, animations: {
                    self.overlayView.gridLinesAlpha = 0
                    self.overlayView.blur = true
                }, completion: {
                })
            }
        } else {
            self.updateCropBoxFrameWithPanGesturePoint(point)
        }
    }

    func scrollViewZoomScaleToBounds() -> CGFloat {
        let scaleW = self.scrollView.bounds.size.width / self.imageView.bounds.size.width
        let scaleH = self.scrollView.bounds.size.height / self.imageView.bounds.size.height
        return max(scaleW, scaleH)
    }

    func willSetScrollViewZoomScale(_ zoomScale: CGFloat) {
        if zoomScale > self.scrollView.maximumZoomScale {
            self.scrollView.maximumZoomScale = zoomScale
        }
        if zoomScale < self.scrollView.minimumZoomScale {
            self.scrollView.minimumZoomScale = zoomScale
        }
    }

    func photoTranslation() -> CGPoint {
        let rect = self.imageView.convert(self.imageView.bounds, to: view)
        let point = CGPoint(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2)
        let zeroPoint = CGPoint(x: view.frame.width / 2, y: self.defaultCropBoxCenter.y)

        return CGPoint(x: point.x - zeroPoint.x, y: point.y - zeroPoint.y)
    }

    func matchScrollViewAndCropView(animated: Bool = false,
                                    targetCropBoxFrame: CGRect = .zero,
                                    extraZoomScale: CGFloat = 1.0,
                                    blurLayerAnimated: Bool = false,
                                    animations: (() -> Void)? = nil,
                                    completion: (() -> Void)? = nil) {
        var targetCropBoxFrame = targetCropBoxFrame
        if targetCropBoxFrame.equalTo(.zero) {
            targetCropBoxFrame = self.overlayView.cropBoxFrame
        }

        let scaleX = self.maxCropRegion.size.width / targetCropBoxFrame.size.width
        let scaleY = self.maxCropRegion.size.height / targetCropBoxFrame.size.height

        let scale = min(scaleX, scaleY)

        // calculate the new bounds of crop view
        let newCropBounds = CGRect(x: 0, y: 0, width: scale * targetCropBoxFrame.size.width, height: scale * targetCropBoxFrame.size.height)

        // calculate the new bounds of scroll view
        let rotatedRect = newCropBounds.applying(CGAffineTransform(rotationAngle: self.totalAngle))
        let width = rotatedRect.size.width
        let height = rotatedRect.size.height

        let cropBoxFrameBeforeZoom = targetCropBoxFrame

        let zoomRect = self.backgroundView.convert(cropBoxFrameBeforeZoom, to: self.imageView) // zoomRect is base on imageView when scrollView.zoomScale = 1
        let center = CGPoint(x: zoomRect.origin.x + zoomRect.size.width / 2, y: zoomRect.origin.y + zoomRect.size.height / 2)
        let normalizedCenter = CGPoint(x: center.x / (self.imageView.width / self.scrollView.zoomScale), y: center.y / (self.imageView.height / self.scrollView.zoomScale))

        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.overlayView.setCropBoxFrame(CGRect(center: self.defaultCropBoxCenter, size: newCropBounds.size), blurLayerAnimated: blurLayerAnimated)
            animations?()

            self.scrollView.bounds = CGRect(x: 0, y: 0, width: width, height: height)

            var zoomScale = scale * self.scrollView.zoomScale * extraZoomScale
            let scrollViewZoomScaleToBounds = self.scrollViewZoomScaleToBounds()
            if zoomScale < scrollViewZoomScaleToBounds { // Some area not fill image in the cropbox area
                zoomScale = scrollViewZoomScaleToBounds
            }
            if zoomScale > self.scrollView.maximumZoomScale { // Only rotate can make maximumZoomScale to get bigger
                zoomScale = self.scrollView.maximumZoomScale
            }
            self.willSetScrollViewZoomScale(zoomScale)

            self.scrollView.zoomScale = zoomScale

            if let contentOffset = self.contentOffsetBeforTransition {
                self.scrollView.contentOffset = self.safeContentOffsetForScrollView(contentOffset)
            } else {
                let contentOffset = CGPoint(x: normalizedCenter.x * self.imageView.width - self.scrollView.bounds.size.width * 0.5,
                                            y: normalizedCenter.y * self.imageView.height - self.scrollView.bounds.size.height * 0.5)
                self.scrollView.contentOffset = self.safeContentOffsetForScrollView(contentOffset)
            }
        }, completion: { _ in
            completion?()
        })

        self.manualZoomed = true
    }

    func safeContentOffsetForScrollView(_ contentOffset: CGPoint) -> CGPoint {
        var contentOffset = contentOffset
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)

        if self.scrollView.contentSize.height - contentOffset.y <= self.scrollView.bounds.size.height {
            contentOffset.y = self.scrollView.contentSize.height - self.scrollView.bounds.size.height
        }

        if self.scrollView.contentSize.width - contentOffset.x <= self.scrollView.bounds.size.width {
            contentOffset.x = self.scrollView.contentSize.width - self.scrollView.bounds.size.width
        }

        return contentOffset
    }

    func safeCropBoxFrame(_ cropBoxFrame: CGRect) -> CGRect {
        var cropBoxFrame = cropBoxFrame
        // Upon init, sometimes the box size is still 0, which can result in CALayer issues
        if cropBoxFrame.size.width < .ulpOfOne || cropBoxFrame.size.height < .ulpOfOne {
            return CGRect(center: self.defaultCropBoxCenter, size: self.defaultCropBoxSize)
        }

        // clamp the cropping region to the inset boundaries of the screen
        let contentFrame = self.maxCropRegion
        let xOrigin = contentFrame.origin.x
        let xDelta = cropBoxFrame.origin.x - xOrigin
        cropBoxFrame.origin.x = max(cropBoxFrame.origin.x, xOrigin)
        if xDelta < -.ulpOfOne { // If we clamp the x value, ensure we compensate for the subsequent delta generated in the width (Or else, the box will keep growing)
            cropBoxFrame.size.width += xDelta
        }

        let yOrigin = contentFrame.origin.y
        let yDelta = cropBoxFrame.origin.y - yOrigin
        cropBoxFrame.origin.y = max(cropBoxFrame.origin.y, yOrigin)
        if yDelta < -.ulpOfOne {
            cropBoxFrame.size.height += yDelta
        }

        // given the clamped X/Y values, make sure we can't extend the crop box beyond the edge of the screen in the current state
        let maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x
        cropBoxFrame.size.width = min(cropBoxFrame.size.width, maxWidth)

        let maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y
        cropBoxFrame.size.height = min(cropBoxFrame.size.height, maxHeight)

        // Make sure we can't make the crop box too small
        cropBoxFrame.size.width = max(cropBoxFrame.size.width, self.cropBoxMinSize)
        cropBoxFrame.size.height = max(cropBoxFrame.size.height, self.cropBoxMinSize)

        return cropBoxFrame
    }

    // MARK: - Private Methods

    private func updateLayout() {
        self.maxCropRegion = CGRect(x: self.scrollViewContainer.left + self.cropContentInset.left,
                                    y: self.scrollViewContainer.top + self.cropContentInset.top,
                                    width: self.scrollViewContainer.width - self.cropContentInset.left - self.cropContentInset.right,
                                    height: self.scrollViewContainer.height - self.cropContentInset.top - self.cropContentInset.bottom)
        self.defaultCropBoxCenter = CGPoint(x: self.maxCropRegion.midX, y: self.maxCropRegion.midY)

        self.defaultCropBoxSize = {
            let scaleW = self.originalImage.size.width / self.maxCropRegion.size.width
            let scaleH = self.originalImage.size.height / self.maxCropRegion.size.height
            let scale = max(scaleW, scaleH)
            return CGSize(width: self.originalImage.size.width / scale, height: self.originalImage.size.height / scale)
        }()
        let zoomScale = self.scrollView.zoomScale
        self.scrollView.transform = .identity
        self.imageView.transform = .identity

        self.overlayView.cropBoxFrame = CGRect(center: self.defaultCropBoxCenter, size: self.defaultCropBoxSize)

        self.scrollView.bounds = CGRect(x: 0, y: 0, width: self.defaultCropBoxSize.width, height: self.defaultCropBoxSize.height)
        self.scrollView.center = self.backgroundView.convert(self.defaultCropBoxCenter, to: self.scrollViewContainer)
        self.imageView.frame = self.scrollView.bounds

        self.scrollView.zoomScale = zoomScale
    }

    private func resetToDefaultLayout() {
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 20

        self.scrollView.transform = .identity
        self.scrollView.contentSize = self.defaultCropBoxSize
        self.scrollView.contentOffset = .zero

        self.imageView.transform = .identity

        self.imageView.image = self.originalImage

        self.aspectRatioLocked = false
    }

    var contentOffsetBeforTransition: CGPoint?

    private func transitionsView(with coordinator: UIViewControllerTransitionCoordinator) {
        guard self.contentOffsetBeforTransition == nil else { return }
        self.contentOffsetBeforTransition = self.scrollView.contentOffset
        let contentSize = self.scrollView.contentSize
        self.overlayView.isHidden = true
        self.scrollViewContainer.isHidden = true
        self.angleRuler.delegate = nil
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            let newCollection = self.newCollection ?? self.traitCollection
            if newCollection.isBothCompact() || newCollection.isWidthRegular() {
                self.maskLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                self.maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            } else {
                self.maskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                self.maskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            }
        } completion: { [weak self] _ in
            guard let self = self else { return }
            let newCollection = self.newCollection ?? self.traitCollection
            if newCollection.isBothCompact() || newCollection.isWidthRegular() {
                self.angleRuler.setDirection(direction: .vertical)
            } else {
                self.angleRuler.setDirection(direction: .horizontal)
            }
            self.updateLayout()
            if let offset = self.contentOffsetBeforTransition {
                let scaleX = self.scrollView.contentSize.width / contentSize.width
                let scaleY = self.scrollView.contentSize.height / contentSize.height
                let scale = min(scaleX, scaleY)
                self.contentOffsetBeforTransition = CGPoint(x: offset.x * scale, y: offset.y * scale)
            }
            self.setAspectRatio(self.aspectRatioView.selectedAspectRatio, animated: false)
            self.setStraightenAngle(CGFloat(self.angleRulerValue * CGFloat.pi / 180.0))
            self.angleRuleDidEndEditing()
            self.overlayView.isHidden = false
            self.scrollViewContainer.isHidden = false
            self.angleRuler.value = self.angleRulerValue
            self.angleRuler.delegate = self
            self.contentOffsetBeforTransition = nil
        }
    }

}

// MARK: UIScrollViewDelegate

extension STCropperViewController: UIScrollViewDelegate {

    func viewForZooming(in _: UIScrollView) -> UIView? {
        return self.imageView
    }

    func scrollViewWillBeginZooming(_: UIScrollView, with _: UIView?) {
        self.cancelStasis()
        self.overlayView.blur = false
        self.overlayView.gridLinesAlpha = 1
    }

    func scrollViewDidEndZooming(_: UIScrollView, with _: UIView?, atScale scale: CGFloat) {
        self.matchScrollViewAndCropView(animated: true, completion: {
            self.stasisAndThenRun {
                UIView.animate(withDuration: 0.25, animations: {
                    self.overlayView.gridLinesAlpha = 0
                    self.overlayView.blur = true
                })

                self.manualZoomed = true
            }
        })
    }

    func scrollViewWillBeginDragging(_: UIScrollView) {
        self.cancelStasis()
        self.overlayView.blur = false
        self.overlayView.gridLinesAlpha = 1
    }

    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.matchScrollViewAndCropView(animated: true, completion: {
                self.stasisAndThenRun {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.overlayView.gridLinesAlpha = 0
                        self.overlayView.blur = true
                    })
                }
            })
        }
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        self.matchScrollViewAndCropView(animated: true, completion: {
            self.stasisAndThenRun {
                UIView.animate(withDuration: 0.25, animations: {
                    self.overlayView.gridLinesAlpha = 0
                    self.overlayView.blur = true
                })
            }
        })
    }
}

// MARK: UIGestureRecognizerDelegate

extension STCropperViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.cropBoxPanGesture {
            guard self.isCropBoxPanEnabled else {
                return false
            }
            let tapPoint = gestureRecognizer.location(in: view)

            let frame = self.overlayView.cropBoxFrame

            let d = self.cropBoxHotArea / 2.0
            let innerFrame = frame.insetBy(dx: d, dy: d)
            let outerFrame = frame.insetBy(dx: -d, dy: -d)

            if innerFrame.contains(tapPoint) || !outerFrame.contains(tapPoint) {
                return false
            }
        }

        return true
    }
}

// MARK: AspectRatioPickerDelegate

extension STCropperViewController: STAspectRatioViewDelegate {

    func aspectRatioViewDidSelectedAspectRatio(_ aspectRatio: STAspectRatio) {
        self.setAspectRatio(aspectRatio)
    }

}

// MARK: Add capability from protocols

extension STCropperViewController: STStasisable, STAngleAssist, STCropBoxEdgeDraggable, STAspectRatioSettable {}


extension STCropperViewController: STCropRotateToolBarDelegate {

    func flipButtonDidPress() {
        self.flip()
    }

    func rotateButtonDidPress() {
        self.rotate90degrees() {
            self.matchScrollViewAndCropView()
        }
    }

    func aspectRatioButtonDidPress(isSelected: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.rulerBackgroundView.alpha = isSelected ? 0.0 : 1.0
            self.aspectRatioView.alpha = !isSelected ? 0.0 : 1.0
        }
    }

}

extension STCropperViewController: STAngleRulerDelegate {

    func angleRuleDidChangeValue(value: CGFloat) {
        self.angleRulerValue = value
        self.rulerValueLabel.text = "\(Int(value))"

        self.scrollViewContainer.isUserInteractionEnabled = false
        self.setStraightenAngle(CGFloat(self.angleRuler.value * CGFloat.pi / 180.0))
    }

    func angleRuleDidEndEditing() {
        UIView.animate(withDuration: 0.25, animations: {
            self.overlayView.gridLinesAlpha = 0
            self.overlayView.blur = true
        }, completion: { _ in
            self.scrollViewContainer.isUserInteractionEnabled = true
            self.overlayView.gridLinesCount = 2
        })
    }

}
