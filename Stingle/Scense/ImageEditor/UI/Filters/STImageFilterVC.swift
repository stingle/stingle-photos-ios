//
//  STImageFilterVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 12/7/21.
//

import UIKit
import MetalPetal

class STImageFilterVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filterTItleBackgrounView: UIView!
    @IBOutlet weak var filterTitleLabel: UILabel!
    @IBOutlet weak var filterCollectionView: STFilterCollectionView!
    @IBOutlet weak var rulerBackgroundView: UIView!
    @IBOutlet weak var gradientView: UIView!
    
    private var mtImage: MTIImage?

    private var image: UIImage? {
        didSet {
            if self.isViewLoaded {
                self.imageView.image = self.image
            }
            guard let image = self.image else {
                return
            }
            if let ciImage = CIImage(image: image) {
                self.mtImage = MTIImage(ciImage: ciImage, isOpaque: true)
            } else if let ciImage = image.ciImage {
                self.mtImage = MTIImage(ciImage: ciImage, isOpaque: true)
            }
        }
    }

    var topToolBar: UIView? = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.text = "ADJUST"
        return label
    }()

    private var selectedFilterType: STFilterType = .allCases.first ?? .exposure

    private let colorControlsFilter = STColorControlsFilter()
    private let whitePointFilter = STWhitePointFilter()
    private let vibranceFilter = STVibranceFilter()
    private let exposureFilter = STExposureFilter()
    private let highlightShadowFilter = STHighlightShadowFilter()
    private let temperatureAndTintFilter = STTemperatureAndTintFilter()
    private let sharpnessFilter = STSharpnessFilter()
    private let noiseReductionFilter = STNoiseReductionFilter()
    private let vignetteFilter = STVignetteFilter()

    lazy var angleRuler = STAngleRuler(frame: self.rulerBackgroundView.bounds)

    private var filters: [IFilter] {
        return [
            self.exposureFilter,
            self.highlightShadowFilter,
            self.colorControlsFilter,
            self.whitePointFilter,
            self.vibranceFilter,
            self.temperatureAndTintFilter,
            self.sharpnessFilter,
            self.noiseReductionFilter,
            self.vignetteFilter
        ]
    }

    private lazy var renderContext: MTIContext? = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        return try? MTIContext(device: device)
    }()

    private lazy var maskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let clear = UIColor.clear.cgColor
        let black = UIColor.black.cgColor
        layer.colors = [clear, black, black, clear]
        layer.locations = [0, 0.08, 0.92, 1]
        layer.frame = self.gradientView.bounds
        if STSizeClassesUtility.isBothCompact(collection: self.traitCollection) || STSizeClassesUtility.isWidthRegular(collection: self.traitCollection) {
            layer.startPoint = CGPoint(x: 0.5, y: 0.0)
            layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        } else {
            layer.startPoint = CGPoint(x: 0.0, y: 0.5)
            layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        }
        return layer
    }()

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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if STSizeClassesUtility.isBothCompact(collection: self.traitCollection) || STSizeClassesUtility.isWidthRegular(collection: self.traitCollection) {
            self.angleRuler.setDirection(direction: .vertical)
            self.filterCollectionView.setScrollDirection(scrollDirection: .vertical)
        } else {
            self.angleRuler.setDirection(direction: .horizontal)
            self.filterCollectionView.setScrollDirection(scrollDirection: .horizontal)
        }

        self.angleRuler.value = self.selectedFilterValue()
        self.angleRuler.delegate = self
        self.filterCollectionView.selectionDelegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.maskLayer.frame = self.gradientView.bounds
        if STSizeClassesUtility.isBothCompact(collection: self.traitCollection) || STSizeClassesUtility.isWidthRegular(collection: self.traitCollection) {
            self.filterCollectionView.setScrollDirection(scrollDirection: .vertical)
        } else {
            self.filterCollectionView.setScrollDirection(scrollDirection: .horizontal)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.transitionView(to: self.traitCollection, with: coordinator)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.transitionView(to: newCollection, with: coordinator)
    }

    func setImage(image: UIImage, applyFilters: Bool = false) {
        self.image = image
        if applyFilters {
            guard let mtImage = self.mtImage else {
                return
            }
            self.imageView.image = self.filterImage(mtImage: mtImage) ?? self.image
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

    func applyFilters(image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }
        let mtImage = MTIImage(ciImage: ciImage, isOpaque: true)
        return self.filterImage(mtImage: mtImage) ?? image
    }

    // MARK: - Private methods

    private func image(from mtImage: MTIImage?) -> UIImage? {
        guard let mtImage = mtImage, let context = self.renderContext else {
            return self.image
        }
        do {
            let ciImage = try context.makeCIImage(from: mtImage)
            let context = CIContext()
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            return UIImage(cgImage: cgImage)
        } catch {
            return self.image
        }
    }

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
            self.sharpnessFilter.value = value
        case .noiseReduction:
            self.noiseReductionFilter.value = value
        case .vignette:
            self.vignetteFilter.value = value
        }
    }

    private func filterImage(mtImage: MTIImage) -> UIImage? {
        var mtFilters = [MTIUnaryFilter]()
        for filter in self.filters {
            guard let ciFilter = filter.ciFilter else { continue }
            let mtFilter = MTICoreImageUnaryFilter()
            mtFilter.filter = ciFilter
            mtFilters.append(mtFilter)
        }
        guard !mtFilters.isEmpty else {
            return nil
        }
        let newImage = FilterGraph.makeImage { output in
            mtImage => mtFilters[0]
            for index in 1..<mtFilters.count {
                mtFilters[index - 1] => mtFilters[index]
            }
            mtFilters.last! => output
        }
        return self.image(from: newImage)
    }

    private func filterValue(type: STFilterType) -> CGFloat {
        var value: CGFloat = 0.0
        switch type {
        case .brightness:
            value = self.colorControlsFilter.brightness ?? STColorControlsFilter.brightnessRange.defaultValue
        case .contrast:
            value = self.colorControlsFilter.contrast ?? STColorControlsFilter.contrastRange.defaultValue
        case .saturation:
            value = self.colorControlsFilter.saturation ?? STColorControlsFilter.saturationRange.defaultValue
        case .vibrance:
            value = self.vibranceFilter.value ?? STVibranceFilter.range.defaultValue
        case .exposure:
            value = self.exposureFilter.value ?? STExposureFilter.range.defaultValue
        case .highlights:
            value = self.highlightShadowFilter.highlight ?? STHighlightShadowFilter.highlightRange.defaultValue
        case .shadows:
            value = self.highlightShadowFilter.shadow ?? STHighlightShadowFilter.shadowRange.defaultValue
        case .whitePoint:
            value = self.whitePointFilter.value ?? STWhitePointFilter.range.defaultValue
        case .temperature:
            value = self.temperatureAndTintFilter.temperature ?? STTemperatureAndTintFilter.temperatureRange.defaultValue
        case .tint:
            value = self.temperatureAndTintFilter.tint ?? STTemperatureAndTintFilter.tintRange.defaultValue
        case .sharpness:
            value = self.sharpnessFilter.value ?? STSharpnessFilter.range.defaultValue
        case .noiseReduction:
            value = self.noiseReductionFilter.value ?? STNoiseReductionFilter.range.defaultValue
        case .vignette:
            value = self.vignetteFilter.value ?? STVignetteFilter.range.defaultValue
        }
        return STFilterHelper.rullerValue(for: type, filterValue: value)
    }

    private func transitionView(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.angleRuler.delegate = nil
        coordinator.animate { [weak self] _ in
            if STSizeClassesUtility.isBothCompact(collection: newCollection) || STSizeClassesUtility.isWidthRegular(collection: newCollection) {
                self?.maskLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                self?.maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            } else {
                self?.maskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                self?.maskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            }
        } completion: { [weak self] _ in
            if STSizeClassesUtility.isBothCompact(collection: newCollection) || STSizeClassesUtility.isWidthRegular(collection: newCollection) {
                self?.angleRuler.setDirection(direction: .vertical)
            } else {
                self?.angleRuler.setDirection(direction: .horizontal)
            }
            self?.angleRuler.value = self?.selectedFilterValue() ?? 0.0
            self?.angleRuler.delegate = self
        }
    }

}

extension STImageFilterVC: STAngleRulerDelegate {

    func angleRuleDidChangeValue(value: CGFloat) {
        self.setSelectedFilterValue(rullerValue: value)
        self.filterCollectionView.setSelectedFilterValue(value: value)
        self.imageView.image = self.filterImage(mtImage: self.mtImage!) ?? self.image
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
