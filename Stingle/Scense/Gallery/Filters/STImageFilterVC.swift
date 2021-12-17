//
//  STImageFilterVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 12/7/21.
//

import UIKit
import MetalPetal

enum STImageFilterType {
    case brightness
    case contrast
    case saturation
    case vibrance
    case exposure

    var title: String {
        switch self {
        case .brightness:
            return "Brightness"
        case .contrast:
            return "Contrast"
        case .saturation:
            return "Saturation"
        case .vibrance:
            return "Vibrance"
        case .exposure:
            return "Exposure"
        }
    }
}

class STImageFilter {
    let type: STImageFilterType
    let min: Float
    let max: Float
    var value: Float

    let defaultValue: Float

    init(type: STImageFilterType, min: Float, max: Float, defaultValue: Float) {
        self.type = type
        self.min = min
        self.max = max
        self.defaultValue = defaultValue
        self.value = defaultValue
    }
}

class STImageFilterVC: UIViewController {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sliderValueLabel: UILabel!

    private var mtImage: MTIImage?

    private var photoFile: STLibrary.File?

    private var selectedFilter: STImageFilter!

    private var filters = [
        STImageFilter(type: .brightness, min: -0.5, max: 0.5, defaultValue: 0.0),
        STImageFilter(type: .contrast, min: 0.0, max: 2.0, defaultValue: 1.0),
        STImageFilter(type: .saturation, min: 0.0, max: 2.0, defaultValue: 1.0),
        STImageFilter(type: .vibrance, min: -1.0, max: 1.0, defaultValue: 0.0),
        STImageFilter(type: .exposure, min: -1.0, max: 1.0, defaultValue: 0.0)
    ]

    private var renderContext: MTIContext? = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        return try? MTIContext(device: device)
    }()

    private func image(from mtImage: MTIImage?) -> UIImage? {
        guard let mtImage = mtImage, let context = self.renderContext else {
            return nil
        }
        do {
            let ciImage = try context.makeCIImage(from: mtImage)
            return UIImage(ciImage: ciImage)
        } catch {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let photoFile = self.photoFile else {
            self.imageView.image = nil
            return
        }

        guard let source = STImageView.Image(file: photoFile, isThumb: false) else {
            return
        }
        STApplication.shared.downloaderManager.imageRetryer.download(source: source) { result in
            DispatchQueue.main.async {
                guard let ciImage = CIImage(image: result) else {
                    return
                }
                self.mtImage = MTIImage(ciImage: ciImage)
                self.imageView.image = result
            }
        } progress: { progress in

        } failure: { error in

        }
        let filter = self.filters.first!
        self.selectFilter(filter: filter)
    }

    @IBAction func sliderValueChanged(_ sender: Any) {
        self.selectedFilter.value = self.slider.value
        self.sliderValueLabel.text = "\(self.selectedFilter.value)"
        var newImage: MTIImage?
        switch self.selectedFilter.type {
        case .brightness:
//            self.mtImage = self.mtImage?.adjusting(brightness: self.selectedFilter.defaultValue)
//            guard let mtImage = mtImage else {
//                return
//            }
//
//            let filter = MTICoreImageKernel.image(byProcessing: mtImage, using: CIFilter(name: "CIVibrance")!, outputDimensions: MTITextureDimensions.init(cgSize: mtImage.size))
            newImage = self.mtImage?.adjusting(brightness: self.selectedFilter.value)
//            self.imageView.image = self.image(from: newImage)
        case .contrast:
//            self.mtImage = self.mtImage?.adjusting(contrast: self.selectedFilter.defaultValue)
            newImage = self.mtImage?.adjusting(contrast: self.selectedFilter.value)
        case .saturation:
//            self.mtImage = self.mtImage?.adjusting(saturation: self.selectedFilter.defaultValue)
            newImage = self.mtImage?.adjusting(saturation: self.selectedFilter.value)
        case .vibrance:
//            self.mtImage = self.mtImage?.adjusting(vibrance: self.selectedFilter.defaultValue)
            newImage = self.mtImage?.adjusting(vibrance: self.selectedFilter.value)
        case .exposure:
//            self.mtImage = self.mtImage?.adjusting(exposure: self.selectedFilter.defaultValue)
            newImage = self.mtImage?.adjusting(exposure: self.selectedFilter.value)
        }
        self.imageView.image = self.image(from: newImage)
    }

    // MARK: - Private methods

    private func selectFilter(filter: STImageFilter) {
        guard let index = self.filters.firstIndex(where: { $0.type == filter.type }) else {
            return
        }
        self.slider.minimumValue = filter.min
        self.slider.maximumValue = filter.max
        self.slider.value = filter.value
        self.pickerView.selectRow(index, inComponent: 0, animated: false)
        self.sliderValueLabel.text = "\(filter.value)"
        self.selectedFilter = filter
    }

}

extension STImageFilterVC: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.filters.count
    }

}

extension STImageFilterVC: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.filters[row].type.title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectFilter(filter: self.filters[row])
    }

}

extension STImageFilterVC {

    static func create(photoFile: STLibrary.File?) -> STImageFilterVC {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STImageFilterVC")
        vc.photoFile = photoFile
        return vc
    }

}
