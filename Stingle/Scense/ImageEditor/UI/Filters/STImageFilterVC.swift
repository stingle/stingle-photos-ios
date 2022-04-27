//
//  STImageFilterVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 12/7/21.
//

import UIKit

protocol STImageFilterVCDelegate: AnyObject {
    func imageFilter(didSelectResize vc: STImageFilterVC)
    func imageFilter(didChange vc: STImageFilterVC)
}

class STImageFilterVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filterTItleBackgrounView: UIView!
    @IBOutlet weak var filterTitleLabel: UILabel!
    @IBOutlet weak var filterCollectionView: STFilterCollectionView!
    @IBOutlet weak var rulerBackgroundView: UIView!
    @IBOutlet weak var gradientView: UIView!

    weak var delegate: STImageFilterVCDelegate?

    private var image: UIImage? {
        didSet {
            if self.isViewLoaded {
                self.imageView.image = self.image
            }
        }
    }

    private var _topToolBar: STFilterToolBar?
    var topToolBar: UIView? {
        if self._topToolBar == nil {
            self._topToolBar = UIView.loadView(fromNib: "STFilterToolBar", withType: STFilterToolBar.self)
            self._topToolBar?.delegate = self
        }
        return self._topToolBar
    }

    private var selectedFilterType: STFilterType = .allCases.first ?? .exposure

    private let colorControlsFilter = STFilter.colorControls
    private let whitePointFilter = STFilter.whitePoint
    private let vibranceFilter = STFilter.vibrance
    private let exposureFilter = STFilter.exposure
    private let highlightShadowFilter = STFilter.highlightShadow
    private let temperatureAndTintFilter = STFilter.temperatureAndTint
    private let noiseReductionAndSharpnessFilter = STFilter.noiseReductionAndSharpness
    private let vignetteFilter = STFilter.vignette

    private var newCollection: UITraitCollection?

    private lazy var angleRuler = STRulerView(frame: self.rulerBackgroundView.bounds)

    private var queue = DispatchQueue(label: "filter.image")

    private let context = CIContext()

    private var filters: [IFilter] {
        return [
            self.exposureFilter,
            self.highlightShadowFilter,
            self.colorControlsFilter,
            self.whitePointFilter,
            self.vibranceFilter,
            self.temperatureAndTintFilter,
            self.noiseReductionAndSharpnessFilter,
            self.vignetteFilter
        ]
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

    var hasChanges: Bool {
        return self.filters.contains(where: { $0.hasChange })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.image
        self.filterTItleBackgrounView.layer.cornerRadius = self.filterTItleBackgrounView.frame.height / 4
        self.angleRuler.translatesAutoresizingMaskIntoConstraints = false
        self.rulerBackgroundView.addSubview(self.angleRuler)
        NSLayoutConstraint.activate([
            self.angleRuler.leadingAnchor.constraint(equalTo: self.rulerBackgroundView.leadingAnchor),
            self.angleRuler.topAnchor.constraint(equalTo: self.rulerBackgroundView.topAnchor),
            self.angleRuler.trailingAnchor.constraint(equalTo: self.rulerBackgroundView.trailingAnchor),
            self.angleRuler.bottomAnchor.constraint(equalTo: self.rulerBackgroundView.bottomAnchor)
        ])
        self.gradientView.layer.mask = self.maskLayer
        self.selectFilter(type: self.selectedFilterType)
        self.reset()
        self.gradientView.alpha = 0.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.traitCollection.isBothCompact() || self.traitCollection.isWidthRegular() {
            self.angleRuler.setDirection(direction: .vertical)
            self.filterCollectionView.setScrollDirection(scrollDirection: .vertical)
        } else {
            self.angleRuler.setDirection(direction: .horizontal)
            self.filterCollectionView.setScrollDirection(scrollDirection: .horizontal)
        }

        self.angleRuler.value = self.selectedFilterValue()
        self.angleRuler.delegate = self
        self.filterCollectionView.selectionDelegate = self
        UIView.animate(withDuration: 0.1) {
            self.gradientView.alpha = 1.0
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.maskLayer.frame = self.gradientView.bounds
        if self.traitCollection.isBothCompact() || self.traitCollection.isWidthRegular() {
            self.filterCollectionView.setScrollDirection(scrollDirection: .vertical)
        } else {
            self.filterCollectionView.setScrollDirection(scrollDirection: .horizontal)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.transitionView(with: coordinator)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.newCollection = newCollection
        self.transitionView(with: coordinator)
    }

    func setImage(image: UIImage, applyFilters: Bool = false) {
        self.image = image
        if applyFilters {
            self.filterImage(image: image) { [weak self] image in
                self?.imageView.image = image ?? self?.image
            }

        }
    }

    func reset() {
        self.imageView.image = self.image
        self.filters.forEach({ $0.reset() })
        self.filterCollectionView.reloadData()
        let value = self.selectedFilterValue()
        self.angleRuler.value = value
        self.filterCollectionView.selectItem(indexPath: IndexPath(item: self.selectedFilterType.rawValue, section: 0))
        self.filterCollectionView.setSelectedFilterValue(value: value)
    }

    func applyFilters(image: UIImage, completion: @escaping (UIImage) -> Void) {
        self.filterImage(image: image) { filteredImage in
            completion(filteredImage ?? image)
        }
    }

    // MARK: - Private methods

    private func selectFilter(type: STFilterType) {
        self.selectedFilterType = type
        self.filterTitleLabel.text = type.title
        let value = self.selectedFilterValue()
        let values = STFilterHelper.rullerMinMaxValues(for: type)
        self.angleRuler.minimumValue = values.min
        self.angleRuler.maximumValue = values.max
        self.angleRuler.defaultValue = values.default
        self.angleRuler.alpha = 0.0
        self.angleRuler.value = value
        UIView.animate(withDuration: 0.2, animations: {
            self.angleRuler.alpha = 1.0
        })
    }

    private func selectedFilterValue() -> CGFloat {
        return self.filterValue(type: self.selectedFilterType)
    }

    private func setSelectedFilterValue(rullerValue: CGFloat) {
        let value = STFilterHelper.value(for: self.selectedFilterType, rullerValue: rullerValue)
        switch self.selectedFilterType {
        case .brightness:
            self.colorControlsFilter.brightness = value
        case .contrast:
            self.colorControlsFilter.contrast = value
        case .saturation:
            self.colorControlsFilter.saturation = value
        case .vibrance:
            self.vibranceFilter.value = value
        case .exposure:
            self.exposureFilter.value = value
        case .highlights:
            self.highlightShadowFilter.highlight = value
        case .shadows:
            self.highlightShadowFilter.shadow = value
        case .whitePoint:
            self.whitePointFilter.value = value
        case .temperature:
            self.temperatureAndTintFilter.temperature = value
        case .tint:
            self.temperatureAndTintFilter.tint = value
        case .sharpness:
            self.noiseReductionAndSharpnessFilter.sharpness = value
        case .noiseReduction:
            self.noiseReductionAndSharpnessFilter.reduction = value
        case .vignette:
            self.vignetteFilter.value = value
        }
    }

    private func filterImage(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        self.queue.async { [weak self] in
            autoreleasepool { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                guard var ciImage = CIImage(image: image) else {
                    completion(nil)
                    return
                }
                for filter in weakSelf.filters {
                    guard let ciFilter = filter.ciFilter, filter.hasChange  else {
                        continue
                    }
                    ciFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    guard let newImage = ciFilter.outputImage else { continue }
                    ciImage = newImage
                }
                guard let cgImage = weakSelf.context.createCGImage(ciImage, from: ciImage.extent) else {
                    completion(nil)
                    return
                }
                let newImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(newImage)
                }
            }
        }
    }

    private func filterValue(type: STFilterType) -> CGFloat {
        var value: CGFloat = 0.0
        switch type {
        case .brightness:
            value = self.colorControlsFilter.brightness ?? STFilterHelper.Constance.ColorControls().brightnessRange.defaultValue
        case .contrast:
            value = self.colorControlsFilter.contrast ?? STFilterHelper.Constance.ColorControls().contrastRange.defaultValue
        case .saturation:
            value = self.colorControlsFilter.saturation ?? STFilterHelper.Constance.ColorControls().saturationRange.defaultValue
        case .vibrance:
            value = self.vibranceFilter.value ?? STFilterHelper.Constance.Vibrance().range.defaultValue
        case .exposure:
            value = self.exposureFilter.value ?? STFilterHelper.Constance.Exposure().range.defaultValue
        case .highlights:
            value = self.highlightShadowFilter.highlight ?? STFilterHelper.Constance.HighlightShadow().highlightRange.defaultValue
        case .shadows:
            value = self.highlightShadowFilter.shadow ?? STFilterHelper.Constance.HighlightShadow().shadowRange.defaultValue
        case .whitePoint:
            value = self.whitePointFilter.value ?? STFilterHelper.Constance.WhitePoint().range.defaultValue
        case .temperature:
            value = self.temperatureAndTintFilter.temperature ?? STFilterHelper.Constance.TemperatureAndTint().temperatureRange.defaultValue
        case .tint:
            value = self.temperatureAndTintFilter.tint ?? STFilterHelper.Constance.TemperatureAndTint().tintRange.defaultValue
        case .sharpness:
            value = self.noiseReductionAndSharpnessFilter.sharpness ?? STFilterHelper.Constance.NoiseReductionAndSharpness().sharpnessRange.defaultValue
        case .noiseReduction:
            value = self.noiseReductionAndSharpnessFilter.reduction ?? STFilterHelper.Constance.NoiseReductionAndSharpness().reductionRange.defaultValue
        case .vignette:
            value = self.vignetteFilter.value ?? STFilterHelper.Constance.Vignette().range.defaultValue
        }
        return STFilterHelper.rullerValue(for: type, filterValue: value)
    }

    private func transitionView(with coordinator: UIViewControllerTransitionCoordinator) {
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
            self.angleRuler.value = self.selectedFilterValue()
            self.angleRuler.delegate = self
            self.filterCollectionView.updateSelectedItemPosition()
        }
    }

}

extension STImageFilterVC: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

}

extension STImageFilterVC: STRulerViewDelegate {

    func angleRuleDidChangeValue(value: CGFloat) {
        self.setSelectedFilterValue(rullerValue: value)
        self.filterCollectionView.setSelectedFilterValue(value: value)
        guard let image = self.image else {
            return
        }
        self.filterImage(image: image) { [weak self] filteredImage in
            self?.imageView.image = filteredImage ?? image
        }
    }

    func angleRuleDidEndEditing() {
        self.delegate?.imageFilter(didChange: self)
    }

}

extension STImageFilterVC: STFilterCollectionViewDelegate {

    func filterCollectionViewDidSelect(filter: STFilterType) {
        self.selectFilter(type: filter)
    }

    func filterCollectionValueFor(filter: STFilterType) -> CGFloat {
        return self.filterValue(type: filter)
    }

}

extension STImageFilterVC: STFilterToolBarDelegate {

    func resizeButtonDidPress() {
        self.delegate?.imageFilter(didSelectResize: self)
    }

}
